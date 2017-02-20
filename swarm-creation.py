import boto3

leader=""
managers=[]
workers=[]


client=boto3.client("cloudformation")
data=client.list_stack_resources(StackName="Swarm")
print data.get("StackResourceSummaries")
ec2_client=boto3.client("ec2")
for r in data.get("StackResourceSummaries"):
    if(r.get("ResourceType")=="AWS::EC2::Instance"):
        ec2_id=r.get("PhysicalResourceId")
        print ec2_id
        node=ec2_client.describe_instances(InstanceIds=[ec2_id])
        tags=((node.get("Reservations")[0]).get("Instances")[0]).get("Tags")
        private_ip=((node.get("Reservations")[0]).get("Instances")[0]).get("PrivateIpAddress")
        for t in tags:
            if t.get("Key")=="Role":
                if t.get("Value")=="Worker":
                    workers.append(private_ip)
                if t.get("Value")=="Manager":
                    managers.append(private_ip)
                if t.get("Value") == "Leader":
                    leader=private_ip

command="";

if leader!="":
    command=" --leader-ip " + leader
if len(workers) > 0:
    command+=" --workers " + ",".join(workers)
if len(managers) > 0:
    command+=" --managers " + ",".join(managers)

print command