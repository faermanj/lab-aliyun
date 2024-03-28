Verify credentials and access
```
aliyun ecs DescribeRegions
```

Set desired region
```
export ALIBABA_CLOUD_REGION_ID=cn-hangzhou
export AY_REGION=$ALIBABA_CLOUD_REGION_ID
```

Create VPC network
```
export AY_CIDR_BLOCK=192.168.0.0/16
export AY_VPC_NAME=ay-cluster-vpc

aliyun vpc CreateVpc \
    --RegionId $AY_REGION \
    --CidrBlock $AY_CIDR_BLOCK \
    --VpcName $AY_VPC_NAME | tee .vpc.json

export AY_VPC_ID=$(jq -r '.VpcId' .vpc.json)
echo $AY_VPC_ID
```

Get available zones
```
aliyun ecs DescribeZones --RegionId $AY_REGION | tee .zones.json

export AY_ZONE_A_ID=$(jq -r '.Zones.Zone[0] | .ZoneId' .zones.json)
echo $AY_ZONE_A_ID
```

Create a vswitch in the first zone
```
export AY_VSWITCH_A_CIDR="192.168.1.0/24"
export AY_VSWITCH_NAME="ay-vswitch-a"

aliyun vpc CreateVSwitch \
    --RegionId $AY_REGION \
    --VpcId $AY_VPC_ID \
    --ZoneId $AY_ZONE_A_ID \
    --CidrBlock $AY_VSWITCH_A_CIDR \
    --VSwitchName $AY_VSWITCH_NAME | tee .vswitch_a.json

export AY_VSWITCH_A_ID=$(jq -r '.VSwitchId' .vswitch_a.json)
echo $AY_VSWITCH_A_ID
```

```
export AY_SG_NAME="ay-cluster-sg"

aliyun ecs CreateSecurityGroup \
    --RegionId $AY_REGION \
    --VpcId $AY_VPC_ID \
    --SecurityGroupName $AY_SG_NAME | tee .cluster_sg.json

export AY_SG_ID=$(jq -r '.SecurityGroupId' .cluster_sg.json)
echo $AY_SG_ID 
```

```
# ERROR: parse failed not support flag form -1/-1
aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol icmp --PortRange -1/-1 --SourceCidrIp 0.0.0.0/0

aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol tcp --PortRange 9000/9999 --SourceCidrIp 0.0.0.0/0

aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol tcp --PortRange 10250/10259 --SourceCidrIp 0.0.0.0/0

aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol tcp --PortRange 10256/10256 --SourceCidrIp 0.0.0.0/0

aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol udp --PortRange 4789/4789 --SourceCidrIp 0.0.0.0/0

aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol udp --PortRange 6081/6081 --SourceCidrIp 0.0.0.0/0

aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol tcp --PortRange 30000/32767 --SourceCidrIp 0.0.0.0/0

aliyun ecs AuthorizeSecurityGroup --RegionId $AY_REGION --SecurityGroupId $AY_SG_ID --IpProtocol udp --PortRange 30000/32767 --SourceCidrIp 0.0.0.0/0

```

```
export AY_NLB_NAME="cluster-lb"
export AY_ZONE_MAPPINGS='[{"VSwitchId":"'$AY_VSWITCH_A_ID'","ZoneId":"'$AY_ZONE_A_ID'"}]'


aliyun nlb CreateLoadBalancer \
    --AddressType Internet \
    --RegionId $AY_REGION  \
    --LoadBalancerName $AY_NLB_NAME \
    --VpcId $AY_VPC_ID \
    --ZoneMappings "$AY_ZONE_MAPPINGS" | tee .nlb.json

```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

```
```

