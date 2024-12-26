# Kubespray virtualbox on-premise cluster

### ip settings

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y openssh-server net-tools
```

```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.0.200/24
      gateway4: 192.168.0.1
      nameservers:
        addresses:
          - 164.124.107.9
          - 8.8.8.8
```

```bash
sudo netplan apply
```

### setting up ssh keys

```bash
ssh-keygen -t rsa -q -f ~/.ssh/id_rsa -N '' -C 'k8s' <<< y > /dev/null 2>&1
```

```bash
sudo nano /etc/hosts
```

```plaintext
#IP Settings
192.168.0.200 control-plane
192.168.0.201 worker1
192.168.0.202 worker2
```

```bash
ssh-copy-id control-plane
ssh-copy-id worker1
ssh-copy-id worker2
```

### kubespray setup

```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
cp -rfp inventory/sample/ inventory/mycluster
```

```bash
nano inventory/mycluster/inventory.ini
```

```ini
# This inventory describe a HA typology with stacked etcd (== same nodes as control plane)
# and 3 worker nodes
# See https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html
# for tips on building your # inventory

# Configure 'ip' variable to bind kubernetes services on a different ip than the default iface
# We should set etcd_member_name for etcd cluster. The node that are not etcd members do not need to>
# or can set the empty string value.
[kube_control_plane]
control-plane ansible_host=192.168.0.200 ip=192.168.0.200 etcd_member_name=etcd1 ansible_user=zzingo ansible_become_password=170114

[etcd:children]
kube_control_plane

[kube_node]
worker1 ansible_host=192.168.0.201 ip=192.168.0.201 ansible_user=zzingo ansible_become_password=170114
worker2 ansible_host=192.168.0.202 ip=192.168.0.202 ansible_user=zzingo ansible_become_password=170114
```

```bash
sudo apt update
sudo apt install -y python3-pip
sudo pip3 install -r requirements.txt
```

```bash
ansible all -m ping -i inventory/mycluster/inventory.ini
```

```bash
nano pre_install.yaml
```

```yaml
---
- hosts: all
  tasks:
    - name: "Disabling Firewall"
      become: true
      community.general.ufw:
        state: disabled

    - name: "Disabling Swap on all nodes"
      become: true
      shell:
        cmd: swapoff -a

    - name: "Commenting Swap entries in /etc/fstab"
      become: true
      replace:
        path: /etc/fstab
        regexp: "(.*swap*)"
        replace: '#\1'

    - name: "Installing NTP"
      become: true
      ansible.builtin.apt:
        name: ntp
        update_cache: true
        state: latest

    - name: "Syncronize date"
      become: true
      shell:
        cmd: ntpq -p

    - name: "Restarting NTP service"
      become: true
      service:
        name: ntp
        state: restarted
        enabled: true

    - name: "Set /proc/sys/net/ipv4/ip_forward to 1"
      become: true
      shell:
        cmd: echo '1' > /proc/sys/net/ipv4/ip_forward

    - name: "Create container folder if not exist"
      become: true
      file:
        path: /etc/modules-load.d/
        state: directory

    - name: "Setting /etc/modules-load.d/k8s.conf"
      become: true
      shell:
        cmd: |
          cat <<EOF | tee -a /etc/modules-load.d/k8s.conf
          overlay
          br_netfilter
          EOF

    - name: "Setting /etc/sysctl.d/k8s.conf"
      become: true
      shell:
        cmd: |
          cat <<EOF | tee -a /etc/sysctl.d/k8s.conf
          net.bridge.bridge-nf-call-ip6tables = 1
          net.bridge.bridge-nf-call-iptables  = 1
          net.ipv4.ip_forward                 = 1
          EOF

    - name: "Register the modules required by modprobe in order to the kernel"
      become: true
      shell:
        cmd: |
          modprobe overlay
          modprobe br_netfilter

    - name: "Applying sysctl parameter"
      become: true
      shell:
        cmd: sysctl --system
```

```bash
ansible-playbook -i inventory/mycluster/inventory.ini pre_install.yaml --become --become-user=root
```

```bash
nano inventory/mycluster/group_vars/k8s_cluster/addons.yml
```

```yaml
helm_enabled: true
metrics_server_enabled: true

# MetalLB deployment
metallb_enabled: true
metallb_speaker_enabled: "{{ metallb_enabled }}"
metallb_namespace: "metallb-system"
metallb_version: v0.13.9
metallb_protocol: "layer2"
metallb_port: "7472"
metallb_memberlist_port: "7946"
metallb_config:
  address_pools:
    primary:
      ip_range:
        - 192.168.0.210-192.168.0.230
      auto_assign: true
  layer2:
    - primary
```

```bash
nano inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
```

```yaml
cluster_name: virtual-box
kube_proxy_strict_arp: true
```

```bash
ansible-playbook -v -i inventory/mycluster/inventory.ini cluster.yml --become --become-user=root
```

### kubectl setting

```bash
mkdir ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### cluster 삭제

```bash
ansible-playbook -v -i inventory/mycluster/inventory.ini reset.yml --become --become-user=root
```

### nginx-ingress 설치

- kubespray addon ingress 에서는 service 가 만들어지지 않아 LoadBalancer 타입의 controller 가 만들어지지 않으므로 helm 으로 설치한다
- https://kubernetes.github.io/ingress-nginx/deploy/

```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

### Longhorn 설치

- pre requirement 확인
- curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/scripts/environment_check.sh | bash

- 각 노드에 open-iscsi 설치

```bash
sudo apt update
sudo apt install -y open-iscsi
sudo systemctl status iscsid
sudo systemctl restart iscsid
```

- 각 노드에 nfs-common 설치

```bash
sudo apt update
sudo apt install -y nfs-common
```

- https://github.com/longhorn/longhorn/issues/8697

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

- Longhorn frontend ui
- kubectl port-forward svc/longhorn-frontend 8081:80 -n longhorn-system

### Postgres-operator

- https://github.com/zalando/postgres-operator
  - database 가 안만들어진다..
- Crunchy PostgreSQL Operator
  - 아직 안해봄
- CloudNativePG
  - 아직 안해봄

```bash
# add repo for postgres-operator
helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator

# install the postgres-operator
helm install postgres-operator postgres-operator-charts/postgres-operator

# add repo for postgres-operator-ui
helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui

# install the postgres-operator-ui
helm install postgres-operator-ui postgres-operator-ui-charts/postgres-operator-ui

# port-forwad operator-ui
kubectl port-forward svc/postgres-operator-ui 8081:80

export PGPASSWORD=$(kubectl get secret postgres.nestjs-delivery-db.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)

export PGMASTER=$(kubectl get pods -o jsonpath={.items..metadata.name} -l application=spilo,cluster-name=nestjs-delivery-db,spilo-role=master -n default)
kubectl port-forward $PGMASTER 6432:5432 -n default

로드밸런서 해놓았는데 왜 접속이 안되지?
포트포워딩은 들어가긴 하는데 왜 database 가 없지?
```

- 추후 operator 를 이용해서 postgres 다시 설치 예정

### Tip

- sudo apt update is not valid 에러
  - sudo systemctl status ntp -> failed 상태 확인
  - sudo systemctl restart ntp -> active 상태 확인
  - 왜 ntp 가 꺼져있는지는 확인 필요
- cluster addon 수정
  - ansible-playbook -v -i inventory/mycluster/inventory.ini cluster.yml --become --become-user=root --tags apps,ingress-controller,metallb
  - https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible/ansible.md#ansible-tags

### TODO

- delivery MSA 구축
- argocd 적용
