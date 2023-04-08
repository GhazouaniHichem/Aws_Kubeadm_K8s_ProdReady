#Import boto3 and define ec2 client
import boto3
import time
from botocore.exceptions import WaiterError

#Define the contents of your shell script
script_join_cmd = """
sudo kubeadm token create --print-join-command
"""

get_nodes_script = """
sudo -u ubuntu kubectl get nodes --selector='!node-role.kubernetes.io/control-plane' -o custom-columns=NAME:.metadata.name --no-headers
"""



#Define the tag possessed by the EC2 instances that we want to execute the script on
tag_master='masters.basic-cluster'
tag_worker='nodes.basic-cluster'


def lambda_handler(event, context):
    #Define ec2 and ssm clients
    ec2_client = boto3.client("ec2", region_name='eu-west-3')
    ssm_client = boto3.client('ssm')
    
    #Gather of instances with tag defined earlier
    filtered_instances_master = ec2_client.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': [tag_master]}])
    filtered_instances_worker = ec2_client.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': [tag_worker]}])
    
    #Reservations in the filtered_instances
    reservations_master = filtered_instances_master['Reservations']
    reservations_worker = filtered_instances_worker['Reservations']
    
    #Create a an empty list for instances to execute the shell script within
    exec_list_master=[]
    exec_list_worker=[]
    
    #Iterate through all the instances within the collected resaervations
    #Append 'running' instances to exec list, ignoring 'stopped' and 'terminated' ones
    for reservation in reservations_master:
        for instance in reservation['Instances']:
            print(instance['InstanceId'], " is ", instance['State']['Name'])
            if instance['State']['Name'] == 'running':
                exec_list_master.append(instance['InstanceId'])
        #divider between reservations
        print("**************") 
        
    # Run shell script
    join_cmd = ssm_client.send_command(
        DocumentName ='AWS-RunShellScript',
        Parameters = {'commands': [script_join_cmd]},
        InstanceIds = exec_list_master
    )
    time.sleep(2)
    command_id = join_cmd['Command']['CommandId']
    command_invocation_result = ssm_client.get_command_invocation(CommandId=command_id, InstanceId=exec_list_master[0])

    script_worker = command_invocation_result['StandardOutputContent']
    print(script_worker)
    print('*************')
    time.sleep(2)
    
    for reservation in reservations_worker:
        for instance in reservation['Instances']:
            print(instance['InstanceId'], " is ", instance['State']['Name'])
            if instance['State']['Name'] == 'running':
                exec_list_worker.append(instance['InstanceId'])
        #divider between reservations
        print("**************") 
    
    join_worker = ssm_client.send_command(
        DocumentName ='AWS-RunShellScript',
        Parameters = {'commands': [script_worker]},
        InstanceIds = exec_list_worker
    )
    
    print('****************')
    
    time.sleep(10)
    # Run shell script
    get_nodes = ssm_client.send_command(
        DocumentName ='AWS-RunShellScript',
        Parameters = {'commands': [get_nodes_script]},
        InstanceIds = (exec_list_master[0],))
    time.sleep(2)
    command_id1 = get_nodes['Command']['CommandId']
    command_invocation_result1 = ssm_client.get_command_invocation(CommandId=command_id1, InstanceId=exec_list_master[0])
    nodes = command_invocation_result1['StandardOutputContent']
    lines = nodes.split('\n')
    while("" in lines):
        lines.remove("")
        
        
        
    time.sleep(5)
    for line in lines:
        my_instance = ec2_client.describe_instances(Filters=[{'Name': 'private-dns-name', 'Values': [f"{line}"]}])
        reservations_instance = my_instance['Reservations']
        time.sleep(2)
        for reservation in reservations_instance:
            for instance in reservation['Instances']:
                if instance['State']['Name'] == 'running':
                    providerID_value = f"aws:///{instance['Placement']['AvailabilityZone']}/{instance['InstanceId']}"
                    save_node_config_file = ssm_client.send_command(DocumentName ='AWS-RunShellScript', Parameters = {'commands': [f"sudo -u ubuntu kubectl get node {line} -o yaml > /home/ubuntu/{line}.yaml"]}, InstanceIds = exec_list_master)
                    time.sleep(3)
                    add_providerID_script = f"""
                    #!/bin/bash
                    chmod 666 /home/ubuntu/{line}.yaml
                    providerID_status=$(sudo -u ubuntu yq eval '.spec.providerID' /home/ubuntu/{line}.yaml)
                    if [ $providerID_status = "null" ]; then
                        sudo -u ubuntu yq e -i '.spec.providerID = "{providerID_value}"' /home/ubuntu/{line}.yaml
                    	sudo -u ubuntu sleep 1
                    	sudo -u ubuntu kubectl delete node {line}
                    	sudo -u ubuntu sleep 2
                    	sudo -u ubuntu kubectl apply -f /home/ubuntu/{line}.yaml
                    	sudo -u ubuntu echo "Node now configured"
                    else
                        sudo -u ubuntu echo "Node is correctly configured"	
                    fi                    
                    """
                    time.sleep(1)
                    add_providerID = ssm_client.send_command(DocumentName ='AWS-RunShellScript', Parameters = {'commands': [add_providerID_script]}, InstanceIds = (exec_list_master[0],))
                    time.sleep(2)
                    command_id2 = add_providerID['Command']['CommandId']
                    command_invocation_result2 = ssm_client.get_command_invocation(CommandId=command_id2, InstanceId=exec_list_master[0])
                    print(command_invocation_result2['StandardOutputContent']) ## Returns the status of the execution of the command                    
                    
        print("#####################")
        print(f" Node {line} is configured")
        print("#####################")
        
        

        