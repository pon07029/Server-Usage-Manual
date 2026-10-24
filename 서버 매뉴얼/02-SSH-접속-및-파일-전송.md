# SSH 접속 및 파일 전송

[목차](../README.md) · 서버 주소와 계정은 관리자에게 받습니다.

## 접속

SSH 포트는 **22, 53022**입니다. 공개키·비밀번호 인증과 root 직접 로그인이 현재 허용돼 있습니다. 분석에는 개인 계정을 사용합니다.

Windows PowerShell, macOS/Linux 터미널에서 실행합니다.

```bash
ssh -V
ssh -p 22 USERNAME@SERVER
```

첫 접속의 서버 호스트 키 지문은 관리자에게 확인한 뒤 수락합니다. 53022 포트를 안내받았다면 `-p 53022`를 사용합니다.

## Windows에서 키 생성

PowerShell의 현재 작업폴더 아래 `.server-ssh`에 생성합니다. 개인키 암호(passphrase)는 생성할 때 입력합니다.

```powershell
$keyDir = Join-Path $PWD ".server-ssh"
New-Item -ItemType Directory -Force -Path $keyDir | Out-Null
Set-Content -LiteralPath (Join-Path $keyDir ".gitignore") -Value "*"
$keyPath = Join-Path $keyDir "linux_server"
if (Test-Path -LiteralPath $keyPath) {
    Write-Host "이미 키가 있습니다: $keyPath"
} else {
    ssh-keygen -t ed25519 -f $keyPath -C "linux-server"
}
Get-Content -LiteralPath "$keyPath.pub"
```

`linux_server`는 개인키, `linux_server.pub`는 공개키입니다. 개인키는 PC에 보관하며 서버나 GitHub에 올리지 않습니다. 이후 `KEY_PATH`는 개인키의 실제 절대 경로로 바꿉니다.

macOS/Linux에서는 다음처럼 생성·등록할 수 있습니다.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/linux_server -C linux-server
ssh-copy-id -p 22 -i ~/.ssh/linux_server.pub USERNAME@SERVER
```

## 공개키 수동 등록

서버에 **등록 대상 계정으로 로그인한 상태에서** 실행합니다.

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat >> ~/.ssh/authorized_keys
```

PC의 `.pub` 내용을 한 줄로 붙여넣고 Enter 후 Ctrl+D를 누릅니다. 형식은 `ssh-ed25519 키데이터 설명`입니다. 기존 마지막 줄에 줄바꿈이 없다면 먼저 줄바꿈을 넣어 키가 이어 붙지 않게 합니다. 디렉터리와 파일 소유자는 해당 계정이어야 합니다. root 등록 경로는 `/root/.ssh/authorized_keys`입니다.

PC의 새 터미널에서 테스트합니다.

```bash
ssh -p 22 -i "KEY_PATH" USERNAME@SERVER
```

`Enter passphrase for key`는 개인키 암호를, `USERNAME@SERVER's password`는 서버 계정 비밀번호를 묻습니다.

## Windows ssh-agent

관리자 권한 PowerShell에서 한 번 설정합니다.

```powershell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent
```

이후 평소 사용하는 계정의 일반 PowerShell에서 등록하고 개인키 암호를 입력합니다.

```powershell
ssh-add "KEY_PATH"
ssh-add -l
```

`Identity added`가 나오면 등록된 것입니다. `Set-Service`의 액세스 거부는 관리자 권한 여부를 확인합니다. 자동화는 키가 등록된 동일 Windows 사용자 환경에서 실행합니다.

## VS Code 및 SSH 설정

PC의 `~/.ssh/config`에 작성합니다. Windows에서는 사용자 홈 아래 `.ssh/config`입니다.

```sshconfig
Host vbmi
    HostName SERVER
    User USERNAME
    Port 22
    IdentityFile ~/.ssh/linux_server
    IdentitiesOnly yes
```

`IdentityFile`은 실제 개인키 경로로 수정합니다. 이후 `ssh vbmi`로 접속하고 VS Code의 Remote - SSH에서 `vbmi`를 선택합니다.

## 파일 전송

아래는 **PC에서** 실행합니다. 서버 대상 경로는 자신에게 쓰기 권한이 있어야 합니다.

```bash
# scp 포트 옵션은 대문자 -P
scp -P 22 -i "KEY_PATH" input.txt USERNAME@SERVER:~/
scp -P 22 -i "KEY_PATH" USERNAME@SERVER:~/result.txt .
sftp -P 22 -i "KEY_PATH" USERNAME@SERVER
```

rsync가 설치된 클라이언트에서는 다음처럼 재전송합니다.

```bash
rsync -av --progress -e 'ssh -p 22' ./input/ USERNAME@SERVER:~/input/
```

## 인증 실패 확인

```bash
# PC
ssh -v -o IdentitiesOnly=yes -i "KEY_PATH" USERNAME@SERVER

# 서버 관리자
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin|pubkeyauthentication|passwordauthentication|authorizedkeysfile) '
sudo journalctl -u ssh -n 50 --no-pager
```

서버가 키를 받아들이는데 자동 접속만 실패하면 ssh-agent 등록·키 암호 입력 여부를 확인합니다. 키가 거부되면 대상 계정·공개키·권한을 확인합니다. `Match` 조건이 있으면 사용자·접속 주소에 적용되는 설정도 별도 확인합니다.
