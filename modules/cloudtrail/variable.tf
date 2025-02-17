variable "common" {
  type = object({
    env        = string
    region     = string
    account_id = string
  })
}

variable "bucket" {
  type = object({
    bucket_name_for_TrailLog       = string
    bucket_name_for_TrailAccessLog = string
  })
}
