#!/bin/bash

ss-local -s qq.com -p server_port -l local_port -m chacha20 -k passwd
