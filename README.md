Kubernetes (K8s) Workloads
==========================

## Pre Setup

```sh
$ alias k=kubectl
$ source <(kubectl completion bash)
$ complete -F __start_kubectl k
$ export do="--dry-run=client -o yaml"
```

### vim

To make vim use 2 spaces for a tab edit `~/.vimrc` to contain:

```vim
set tabstop=2
set expandtab
set shiftwidth=2
```

## Yaml

```sh
$ cd yaml
$ k create ns <ns-name>
$ k -n <ns-name> create -f <yaml-manifest>
```

[comment]: # ( vim: set ft=markdown ts=4 sts=4 sw=4 nowrap et: )
