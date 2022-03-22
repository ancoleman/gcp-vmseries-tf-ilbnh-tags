
#public_key_path           = "~/.ssh/gcp-demo.pub"
fw_image_name = "vmseries-flex-byol-1013"

mgmt_sources  = ["0.0.0.0/0"]
regions       = ["us-east1", "us-west1"]
cidrs_mgmt    = ["10.0.0.0/28", "10.0.0.16/28"]
cidrs_untrust = ["10.0.1.0/28", "10.0.1.16/28"]
cidrs_trust   = ["10.0.2.0/28", "10.0.2.16/28"]

fw_machine_type = "n1-standard-4"

panorama_host        = "3.138.239.111"
dg_name              = ""
tmpl_stck_name       = ""
sft_license_auth_key = ""
bucket_name          = ""
project_id           = ""