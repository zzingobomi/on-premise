# Kubespray Raspberry Pi on-premise cluster

### Prerequisite

- Raspberry Pi 4 Model 3개
- 4GB RAM
- Raspberry Pi Imager 를 통해 ubuntu server 22.04.5 설치
  - https://www.raspberrypi.com/software/
  - hostname 설정
  - 사용자 이름및 비밀번호 설정
  - 무선LAN 설정
    - 무선LAN 국가: KR
  - 로케일 설정
    - 시간대: Asia/Seoul
    - 키보드 레이아웃: us
  - ssh 비밀번호 인증 사용
- ipTIME 공유기로 접속해서 내부 네트워크에 Wifi 로 접속되었는지 확인

### 고정 ip 세팅

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
network:
  ...
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.0.{static ip}/24
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
192.168.0.101 hori1
192.168.0.102 hori2
192.168.0.103 hori3
```

```bash
ssh-copy-id hori1@hori1
ssh-copy-id hori2@hori2
ssh-copy-id hori3@hori3
```

### kubespray setup

```bash
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
cp -rfp inventory/sample/ inventory/delivery-cluster
```

```bash
nano inventory/delivery-cluster/inventory.ini
```

```ini
[kube_control_plane]
hori1 ansible_host=192.168.0.101 ip=192.168.0.101 etcd_member_name=etcd1 ansible_user=hori1 ansible_become_password=170114

[etcd:children]
kube_control_plane

[kube_node]
hori2 ansible_host=192.168.0.102 ip=192.168.0.102 ansible_user=hori2 ansible_become_password=170114
hori3 ansible_host=192.168.0.103 ip=192.168.0.103 ansible_user=hori3 ansible_become_password=170114
```

```bash
sudo apt update
sudo apt install -y python3-pip
sudo pip3 install -r requirements.txt
```

##### inventory.ini setting

```bash
ansible all -m ping -i inventory/delivery-cluster/inventory.ini
```

##### pre install ansible setting

```bash
nano pre_install.yaml
```

- linux-modules-extra 를 현재 커널버전에 맞게 설치하지 않으면 Module dummy not found 에러가 난다.
- uname -r 을 입력해서 정확한 커널 버전을 확인한다.
- apt install jq 설정도 추가할것
- control-plane 에서 Newer kernel avalibale 이 나오고 있다
- 재부팅후에는 새 커널이 설치되는지 확인할것
- 새 커널이 설치된다면 Install linux-modules-extra-5.15.0-1061-raspi 단계가 수정되어야 할 수도 있다
- Raspberry Pi 에서는 서비스만 activation 되고 모듈은 자동으로 로드되지 않음
- iscsi_tcp 모듈 활성화 및 자동로드 설정 Task 추가할것

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

    - name: "Install linux-modules-extra-5.15.0-1061-raspi"
      become: true
      ansible.builtin.apt:
        name: linux-modules-extra-5.15.0-1061-raspi
        state: present
        update_cache: true

    - name: "Installing NTP"
      become: true
      ansible.builtin.apt:
        name: ntp
        update_cache: true
        state: present

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

    - name: "Install open-iscsi on all nodes"
      become: true
      ansible.builtin.apt:
        name: open-iscsi
        state: present
        update_cache: true

    - name: "Restart iscsid service"
      become: true
      service:
        name: iscsid
        state: restarted
        enabled: true

    - name: "Install nfs-common on all nodes"
      become: true
      ansible.builtin.apt:
        name: nfs-common
        state: present
        update_cache: true
```

```bash
ansible-playbook -i inventory/delivery-cluster/inventory.ini pre_install.yaml --become --become-user=root
```

##### addons setting

```bash
nano inventory/delivery-cluster/group_vars/k8s_cluster/addons.yml
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
  speaker:
    nodeselector:
      kubernetes.io/os: "linux"
    tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Equal"
        value: ""
        effect: "NoSchedule"
  controller:
    nodeselector:
      kubernetes.io/os: "linux"
    tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Equal"
        value: ""
        effect: "NoSchedule"
  address_pools:
    primary:
      ip_range:
        - 192.168.0.111-192.168.0.130
      auto_assign: true
  layer2:
    - primary
```

##### cluster setting

```bash
nano inventory/delivery-cluster/group_vars/k8s_cluster/k8s-cluster.yml
```

```yaml
cluster_name: delivery-cluster
kube_proxy_strict_arp: true
```

```bash
ansible-playbook -v -i inventory/delivery-cluster/inventory.ini cluster.yml --become --become-user=root
```

### kubectl setting

```bash
mkdir ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### cluster 삭제

```bash
ansible-playbook -v -i inventory/delivery-cluster/inventory.ini reset.yml --become --become-user=root
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
- 현재 Raspberry Pi 에서는 iscsi_tcp 서비스가 실행되고 있어도 모듈이 로드되진 않은 상태이다.
- sudo modprobe iscsi_tcp 로 활성화 시켜놓았다.
- 추후 pre_install 에서 자동으로 활성화 시키는 Task 추가할것

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

### Prometheus Grafana 설치

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# default user // pwd
# admin // prom-operator

# https://grafana.com/grafana/dashboards
# Node Export Full(1860) 대시보드를 통해 CPU, MEM, DISK 사용량 확인
```

### Loki-Stack 설치

- loki-stack 이 더이상 유지되지 않고 그냥 loki 로 유지되고 있는듯하다.
- 그냥 loki는 3버전으로 여러모드로 설치가 가능하다
- 여기서는 그냥 loki-stack 으로 설치한다. 그러나 2.6.X 버전은 kube-prometheus-stack grafana 와 연동되지 않는 이슈가 있다.
- https://community.grafana.com/t/grafana-unable-to-connect-with-loki-please-check-the-server-logs-for-more-details/119757/5
- loki image를 2.9.3 으로 설치해야 데이터 소스가 연결된다.

```bash
helm upgrade --install loki-stack --namespace=monitoring grafana/loki-stack --set loki.image.tag=2.9.3

# grafana 연결
# Connections > Data sources > loki
URL: http://loki-stack:3100

# Home > Explore > loki
# pod 선택해서 로그 확인해보기
# MSA 구축후에 로그 실제로 잘 나오는지 확인할것
# 추후 Longhorn 에 저장 세팅해서 persistence 유지되는지 확인할것
```
