#!/bin/bash
echo "Hello, World" > index.html
echo "${data.terraform_remote_state.db.address}" >> index.html
echo "${data.terraform_remote_state.db.port}" >> index.html
nohup busybox httpd -f -p ${var.server_port} &
