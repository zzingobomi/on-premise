### Raspberry 초기화

- Raspberry Pi imager 실행
- Ubuntu 22.04.5 LTS (64bit) 선택
- hostname, password 세팅
- 무선랜 off (유선이 없다면 무선랜도 하나의 방법 but 국가코드 주의할것)
  - iptime 설정 확인후 국가가 대한민국이면 KR 선택
- 로케일 및 키보드 레이아웃 설정 (Asia/Seoul) (us)
- ssh 활성화
  - Allow public-key authentication only 선택
  - 엔터키 치고 복수의 publickey 등록 가능
- sd 카드 파일 쓰기
- 완료후 network_config 파일 수정

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

- /boot/firmware/cmdline.txt 추가

```text
cgroup_enable=memory cgroup_memory=1
```

- 전원버튼 켜서 iptime 공유기에 연결되는지 확인
- ssh 접속 확인

```bash
ssh <user-name>@<server-ip>
```

- MobaXterm 이용시
  - Advanced SSH settings -> Use private key -> 개인키 세팅

### 현재 세팅

위에서부터 차례대로 hori1, hori2, hori3

### Microk8s 설치

```bash
cd rasp-ansible
ansible all -m ping
ansible-playbook playbook.yaml -v
```

### Pre Requirement 확인

```bash
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/scripts/environment_check.sh | bash
```

### Terraform

- microk8s ingress 는 생성시 자동으로 metallb의 address pool 을 가져오지 않는다. (defualt 127.0.0.1)
- microk8s 가 로컬에서 동작을 디폴트로 전제를 하다보니 설계상의 이슈인듯
- addon ingress 를 비활성화 하고 local-chart 에서 관리한다.

```bash
cd rasp-terraform
terraform init
terraform apply -var-file=dev.tfvars -auto-approve

# 초기 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### TODO

- 왜 처음에 한번 설치할때 한번에 성공하지 못하지?
- 여러번 terraform apply 하면 성공하긴 하는데.. 리소스 문제인가? 타이밍 이슈인가?
- 실행을 한번에 한꺼번에 하지 말고 나눠서 할 수 있을까?
- dashboard login skip
- argocd 최초 설치후 비밀번호를 UI 들어가서 가져와야 하는 이슈
- node taint 설정하기
- terraform 반복되는 구문 최적화 하기
- istio 세팅 istio-base, istiod, istio-ingress 로 이름 바꿔도 되는지 테스트 (각각 base, istiod, gateway 로 받아졌음)
- 기본 쿠버네티스 metallb 는 kube-proxy에 ipvs, strictARP 설정을 해야한다는데 microk8s는 kube-proxy가 따로 없고 다른것과 통합된듯
- ipvs, strictARP 확인은 못했지만 아마 기본값인듯
- 우선 addon의 metallb 를 사용하고 추후 알아보기로 결정

### 참고

https://ubuntu.com/tutorials/how-to-kubernetes-cluster-on-raspberry-pi#1-overview
https://github.com/istvano/ansible_role_microk8s

### 나스에서 공유폴더 생성후 nfs 권한주기

```bash
sudo apt-get update
sudo apt-get install nfs-common

sudo mkdir -p /mnt/synology
sudo mount -t nfs 192.168.0.4:/volume1/backup /mnt/synology
```

### rsync 명령어

```bash
sudo rsync -aAXv --delete --exclude=/dev/* --exclude=/proc/* --exclude=/sys/* --exclude=/tmp/* --exclude=/run/* --exclude=/mnt/* --exclude=/media/* --exclude="swapfile" --exclude="lost+found" --exclude=".cache" / /mnt/synology/hori3/init
```

### Microk8s 초기화

- 현재 라즈베리파이 재부팅시 커널이 자동 업데이트 되는 이슈가 있다
- 자동 업데이트 되면 linux-modules-extra-raspi 버전이 달라지는 이슈가 있어서 설치가 안된다
- 뭔가 방법을 찾아서 계속 동기화를 맞춰줘야 한다 (자동 업데이트 끄기? 커널 버전 고정?)

```bash
sudo snap remove microk8s --purge
sudo reboot
```

### 초기화 스크립트

```bash
#!/bin/bash

# 모든 사용자 설치 패키지 제거
sudo apt-get update
sudo apt-get clean
sudo apt-get autoremove

# 설치된 패키지들을 기본 상태로 재설정
sudo apt-get --purge remove $(dpkg -l | grep '^ii' | awk '{print $2}' | grep -v 'apt\|systemd\|grub\|linux-image\|linux-firmware')
sudo apt-get install ubuntu-minimal

# 사용자 설정 파일들 초기화
sudo rm -rf /home/*/.* /home/*/.[^.]*
sudo rm -rf /root/.*

# 시스템 로그 및 임시 파일 정리
sudo rm -rf /var/log/*
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# systemd 임시 파일 정리
sudo rm -rf /var/lib/systemd/random-seed
sudo rm -rf /var/lib/systemd/timesync/*

# 시스템 재시작
sudo reboot
```
