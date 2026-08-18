
output "ec2_instance_id" {
  value = aws_instance.sample_ins.id
}

output "ec2_tags" {
  value = aws_instance.sample_ins.tags
}