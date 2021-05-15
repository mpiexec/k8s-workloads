---
title: "K8s workloads"
date: "14.05.2021"
theme: "Frankfurt"
navigation: empty
colortheme: "beaver"
fonttheme: "professionalfonts"
fontsize: 10pt
colorlinks: true
urlcolor: blue
linkstyle: bold
aspectratio: 169
section-titles: false
toc: false
mainfont: Ubuntu
...


## What is Kubernetes (k8s)?

\Large
- Kubernetes - это открытое ПО для оркестровки контейнеризированных приложений
автоматизации их развёртывания, масштабирования и координации в условиях 
кластера (c) Wikipedia
\normalsize


## Why do we need k8s?

- Docker?
- Docker-compose?


## K8s pros

- Immutable infrastructure
- Declarative (YAML, IaC)
- Decoupling 
- Self-healing
- Autoscaling
- Service-discovery


## K8s workflow

```plantuml
left to right direction
agent cli as "kubectl"
actor user
agent srv as "api-server"
node cpl as "Control Plane"
storage worker1
storage worker2
storage worker3
cli <--> srv
srv <--> cpl
cpl <--> worker1
cpl <--> worker2
cpl <--> worker3
```


## Workloads/objects

\small
- Pod
- ReplicaSet
- Deployment
- DaemonSet
- StatefulSet
- Job
- CronJob

- Extra:
    - Namespace
    - Static Pod
    - Taint, Tolerations
    - Affinity, Anti-Affinity
    - initContainers
    - Headless Services
    - Resource Management
\normalsize


## Pod 1/2

- Docker -- container
- K8s -- Pod
- Pod -- container(s)
- One container = One Pod, exceptions
    - sidecar
    - /pause

![](./img/s5-k8s-pod.png)


## kubectl

\small
``` bash
$ alias k='kubectl'
# Auto-completion (bash, zhs), kubectl completion --help
$ source <(kubectl completion bash)
$ complete -F __start_kubectl k
# Short object names
$ kubectl api-resources
# Dry-run (k8s >= 1.18)
$ export do='--dry-run=client -o yaml'
$ kubectl run|create ... $do
# Imperative commands
$ kubectl run ...
$ kubectl create ...
# Vim
$ vim ~/.vimrc
set tabstop=2
set expandtab
set shiftwidth=2
# Explain
$ kubectl explain deployment.spec.template.spec.containers.image
```
\normalsize


## Namespace

``` bash
$ kubectl get namespace
$ kubectl create ns <ns-name>
$ kubectl delete ns <ns-name>
$ kubectl describe ns <ns-name>
$ kubectl -n <ns-name> ...
# Namespace, default
$ kubect get pod
# Namespace, specific
$ kubectl -n kube-system get pod
# Labels
$ kubectl get ns --show-labels
$ kubectl label ns <ns-name> foo=bar
$ kubectl label ns <ns-name> foo-
```


## Pod 2/2 +demo

- Imperative

``` bash
$ kubectl run nginx --image=nginx:latest --port=80
```

- Declarative

\scriptsize
``` yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - image: nginx:stable
    name: nginx
    ports:
    - containerPort: 80
```

``` bash
$ kubectl -n sc16 create -f pod.yml
pod/nginx created

$ kubectl -n sc16 get pod
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          6s

$ kubectl -n sc16 get pod -w 
```
\normalsize


## ReplicaSet 1/2

- Parent of Pod
- Desired number of replicas
- Labels
- Selectors


## ReplicaSet 2/2 +demo

::: columns

:::: {.column width=70%}

\small
``` bash
$ kubectl -n sc16 create -f replicaset.yml
replicaset.apps/myrs created

$ kubectl -n sc16 get all
NAME            READY  STATUS   RESTARTS  AGE
pod/myrs-jsxvd  1/1    Running  0         8m2s
pod/myrs-mqp5p  1/1    Running  0         8m2s

NAME                  DESIRED  CURRENT  READY  AGE
replicaset.apps/myrs  2        2        2      8m2s

# Scaling
$ kubectl -n sc16 scale replicaset myrs --replicas=3
replicaset.apps/myrs scaled
$ kubectl -n sc16 edit replicaset myrs
$ kubectl -n sc16 apply -f replicaset.yml

$ kubectl -n sc16 set image rs myrs '*=nginx:alpine'
```
\normalsize

::::

:::: {.column width=30%}

- Declarative

\footnotesize
``` yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: myrs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myrs
  template:
    metadata:
      labels:
        app: myrs
    spec:
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
```
\normalsize

::::

:::


## Deployment 1/3

- Deployment -> ReplicaSet -> Pod
- Suitable for apps update, strategies:
    - Recreate
    - RollingUpdate
- Rollout status/undo/history


## Deployment 2/3

::: columns

:::: {.column width=70%}

- Imperative

\small
``` bash
$ kubectl create deployment deploy --image=nginx ...

$ kubectl -n sc16 create -f deployment.yml
deployment.apps/deploy created

$ kubectl -n sc16 get all
NAME                         READY  STATUS   RESTARTS  AGE
pod/deploy-695849b774-bjdp6  1/1    Running  0         17m
pod/deploy-695849b774-fbzmz  1/1    Running  0         17m
pod/deploy-695849b774-gf97l  1/1    Running  0         17m

NAME                    READY  UP-TO-DATE  AVAILABLE  AGE
deployment.apps/deploy  3/3    3           3          17m

NAME                               DESIRED  CURRENT  READY  AGE
replicaset.apps/deploy-695849b774  3        3        3      17m
```
\normalsize

::::

:::: {.column width=30%}

- Declarative

\scriptsize
``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: deploy
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: deploy
    spec:
      containers:
      - image: nginx
        name: nginx
```
\normalsize

::::

:::


## Deployment 3/3 +demo

- App Update

\scriptsize
``` bash
$ kubectl -n sc16 edit deployment deploy
$ vim deployment.yml
$ kubectl -n sc16 apply -f deployment.yml
$ kubectl -n sc16 set image deployment deploy '*=nginx:alpine' --record
deployment.apps/deploy image updated

$ kubectl -n sc16 get rs
NAME                DESIRED   CURRENT   READY   AGE
deploy-669589559    3         3         3       62s
deploy-695849b774   0         0         0       27m

$ kubectl -n sc16 rollout undo deployment deploy [--to-revision=<revn>]
deployment.apps/deploy rolled back

$ kubectl -n sc16 get rs
NAME                DESIRED   CURRENT   READY   AGE
deploy-669589559    0         0         0       8m47s
deploy-695849b774   3         3         3       34m

$ kubectl rollout <history|pause|restart|resume|status|undo> --help
```
\normalsize


## Resource Management

- Probes:
    - Liveness
    - Readines
    - Startup

- Resources:
    - Requests
    - Limits
    - Cpu
        - 1CPU = 1000m (milliCPU)
        - Throttling
    - Mem
        - 200Mi
        - OOM Killer


## DaemonSet 1/2

- K8s monitoring task
- Possible solutions:
    - static Pod
    - Pod Anti-affinity
    - DaemonSet


## DaemonSet 2/2 +demo

- Declarative

\scriptsize
``` yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ds
spec:
  selector:
    matchLabels:
      app: ds
  template:
    metadata:
      labels:
        app: ds
    spec:
      containers:
      - image: nginx
        name: nginx
```

``` bash
$ kubectl -n sc16 apply -f daemonset.yml
daemonset.apps/ds created

$ kubectl -n sc16 get ds
NAME   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
ds     2         2         2       2            2           <none>          27s
```
\normalsize


## SatefulSet 1/2

- Deployment -- stateless apps
- StatefulSet -- stateful apps
    - Uniq pod names
    - Pod start sequence
    - PVC Template
- Suitable for DBs:
    - Rabbit
    - Redis
    - ...


## SatefulSet 2/2 +demo

::: columns

:::: {.column width=70%}
\scriptsize
``` bash
$ kubectl -n sc16 apply -f statefulset.yml
statefulset.apps/ss created

$ kubectl -n sc16 get all
NAME       READY   STATUS    RESTARTS   AGE
pod/ss-0   1/1     Running   0          115s
pod/ss-1   1/1     Running   0          92s
pod/ss-2   1/1     Running   0          67s

NAME                  READY   AGE
statefulset.apps/ss   3/3     115s
```
\normalsize

---

- Affinity, Anti-Affinity
- initContainers
- Headless Service `.spec.clusterIP: None`

---

\scriptsize
``` bash
$ kubectl explain statefulset.spec.template.spec.initContainers
```
\normalsize

::::

:::: {.column width=30%}
- Declarative

\scriptsize
``` yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ss
spec:
  serviceName: "ss"
  selector:
    matchLabels:
      app: ss
  replicas: 3
  template:
    metadata:
      labels:
        app: ss
    spec:
      containers:
      - name: db
        image: redis:alpine
```
\normalsize
::::

:::


## Job

::: columns

:::: {.column width=70%}
\scriptsize
``` bash
$ kubectl -n sc16 create -f job.yml
job.batch/hell created

$ kubectl -n sc16 get pod -w
NAME         READY   STATUS              RESTARTS   AGE
hell-h954s   0/1     ContainerCreating   0          7s
hell-h954s   0/1     Completed           0          22s

$ kubectl -n sc16 get job
NAME   COMPLETIONS   DURATION   AGE
hell   1/1           22s        93s
```
\normalsize
::::

:::: {.column width=30%}
- Declarative

\scriptsize
``` yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hell
spec:
  backoffLimit: 3
  activeDeadlineSeconds: 30
  template:
    spec:
      containers:
      - image: busybox
        name: hell
        args:
        - /bin/sh
        - -c
        - date; echo Hell world
      restartPolicy: Never
```
\normalsize
::::

:::


## CronJob

::: columns

:::: {.column width=70%}

- concurrencyPolicy
- successfulJobsHistoryLimit
- failedJobsHistoryLimit

---

\scriptsize
``` bash
$ kubectl -n sc16 create -f cronjob.yml
cronjob.batch/cjob created

$ kubectl -n sc16 get cronjob
NAME   SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cjob   */1 * * * *   False     0        26s             2m42s

$ kubectl -n sc16 get job
NAME              COMPLETIONS   DURATION   AGE
cjob-1615812240   1/1           11s        2m24s
cjob-1615812300   1/1           9s         84s
cjob-1615812360   1/1           10s        23s

$ kubectl -n sc16 get pod
NAME                    READY   STATUS      RESTARTS   AGE
cjob-1615812300-nkfrl   0/1     Completed   0          2m37s
cjob-1615812360-8fkzj   0/1     Completed   0          96s
cjob-1615812420-65m5b   0/1     Completed   0          36s
```
\normalsize

::::

:::: {.column width=30%}
- Declarative

\scriptsize
``` yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: cjob
spec:
  schedule: '*/1 * * * *'
  concurrencyPolicy: Allow
  jobTemplate:
    spec:
      backoffLimit: 3
      activeDeadlineSeconds: 30
      template:
        spec:
          containers:
          - image: busybox
            name: cjob
            args:
            - /bin/sh
            - -c
            - date; echo Hell world
          restartPolicy: Never
```
\normalsize
::::

:::


## Links & References

- YAML: <https://github.com/mpiexec/k8s-workloads>
- CKA: <https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/>
- Resources allowed during exam:
    - <https://kubernetes.io/docs/>
    - <https://github.com/kubernetes/>
    - <https://kubernetes.io/blog/>


## Q&A

\Huge\centering Questions?


[comment]: # ( vim: set ft=markdown ts=4 sts=4 sw=4 nowrap et: )
