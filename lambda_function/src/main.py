import os
import boto3

from base import LambdaFunctionBase


class CWScheduledEventManageEC2State(LambdaFunctionBase):
    """
    Class starting or stopping EC2 instances not part of a AutoScaling group.
    """

    # Section specific to the lambda.
    ACTION = os.environ['PARAM_ACTION']
    RESOURCE_TAG_KEY = os.environ['PARAM_RESOURCE_TAG_KEY']
    RESOURCE_TAG_VALUE = os.environ['PARAM_RESOURCE_TAG_VALUE']
    AWS_REGIONS = os.environ['PARAM_AWS_REGIONS'].split(',')

    def _get_ec2_instance_ids_by_tag(self, aws_region_name, instance_state, tag_key, tag_value):
        """ Returns all resources identifiers linked to tag. """
        ec2_client = boto3.client('ec2', region_name=aws_region_name)
        autoscaling_client = boto3.client('autoscaling', region_name=aws_region_name)

        # Finds EC2 instances.
        resource_pages = ec2_client.get_paginator('describe_instances').paginate(
            Filters=[
                {
                    'Name': f'tag:{tag_key}',
                    'Values': [
                        tag_value
                    ]
                },
                {
                    'Name': 'instance-state-name',
                    'Values': [
                        instance_state
                    ]
                }
            ]
        )

        # Browse EC2 instances and exclude EC2 member of a AutoScalingGroup.
        ec2_instance_ids = []
        for resource_page in resource_pages:
            for resource in resource_page['Reservations']:
                for ec2_instance in resource['Instances']:
                    ec2_instance_id = ec2_instance['InstanceId']

                    # Check if part of an autoscaling group.
                    is_part_of_autoscaling_group = len(autoscaling_client.describe_auto_scaling_instances(
                        InstanceIds=[
                            ec2_instance_id,
                        ]
                    )['AutoScalingInstances']) > 0

                    # If not, the instance is eligible.
                    if not is_part_of_autoscaling_group:
                        self.logger.debug('>> Instance %s is eligible.', ec2_instance_id)
                        ec2_instance_ids.append(ec2_instance_id)
                    else:
                        self.logger.debug('>> Instance %s is not eligible as part of an AutoScaling Group.', ec2_instance_id)

        return ec2_instance_ids

    def _stop_ec2_instances(self, aws_region_name, ec2_instance_ids):
        """ Stop the EC2 instances. """
        ec2_client = boto3.client('ec2', region_name=aws_region_name)

        self.logger.info('> Stopping EC2 instances.')
        for ec2_instance_id in ec2_instance_ids:
            self.logger.debug('>> Stopping instance %s.', ec2_instance_id)
            ec2_client.stop_instances(InstanceIds=[ec2_instance_id])
            self.logger.info('>> EC2 Instance %s => [STOPPED].', ec2_instance_id)

    def _start_ec2_instances(self, aws_region_name, ec2_instance_ids):
        """ Start the EC2 instances. """
        ec2_client = boto3.client('ec2', region_name=aws_region_name)

        self.logger.info('> Starting EC2 instances.')
        for ec2_instance_id in ec2_instance_ids:
            self.logger.debug('>> Starting instance %s.', ec2_instance_id)
            ec2_client.start_instances(InstanceIds=[ec2_instance_id])
            self.logger.info('>> EC2 Instance %s => [RUNNING].', ec2_instance_id)

    def _execute(self, event, context):  # pylint: disable=W0613
        """ Execute the method. """
        self.logger.info('Starting the operation.')

        if self.ACTION in ['enable', 'start']:
            ec2_instance_state = 'stopped'
        elif self.ACTION in ['disable', 'stop']:
            ec2_instance_state = 'running'
        else:
            raise Exception('Unexpected action.')

        for aws_region_name in self.AWS_REGIONS:
            self.logger.info('> Searching EC2 instances in region %s having tag %s=%s and state=%s.',
                             aws_region_name, self.RESOURCE_TAG_KEY, self.RESOURCE_TAG_VALUE, ec2_instance_state)

            # Get EC2 by tag.
            ec2_instance_ids = self._get_ec2_instance_ids_by_tag(aws_region_name, ec2_instance_state, self.RESOURCE_TAG_KEY, self.RESOURCE_TAG_VALUE)

            self.logger.info('> Found %s EC2 instances in region %s having tag %s=%s and state=%s.',
                             str(len(ec2_instance_ids)), aws_region_name, self.RESOURCE_TAG_KEY, self.RESOURCE_TAG_VALUE, ec2_instance_state)

            # Start/Stop
            if len(ec2_instance_ids) > 0:
                if self.ACTION in ['enable', 'start']:
                    self._start_ec2_instances(aws_region_name, ec2_instance_ids)
                elif self.ACTION in ['disable', 'stop']:
                    self._stop_ec2_instances(aws_region_name, ec2_instance_ids)

        self.logger.info('Operation completed successfully.')

        return self._build_response_ok()


def lambda_handler(event, context):
    """ Function invoked by AWS. """
    return CWScheduledEventManageEC2State().process_event(event, context)
