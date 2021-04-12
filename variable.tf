variable "allports" {
    type = list(number)
    default = [22,443,80]
  
}

variable "allprivate_ports" {
    type = list(number)
    default = [80,443,22,3306]
    description = "private-subnet-only"
  
}
