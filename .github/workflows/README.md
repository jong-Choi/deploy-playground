```yml
on:
  push:
    branches: [main]
```

해설 : main브랜치에서 푸시 이벤트를 감지하면 깃허브 액션이 실행된다.

```yml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: appleboy/ssh-action@v1.2.0
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            set -e
            trap 'echo "Deploy failed at line $LINENO"' ERR
            cd ~/${{ github.event.repository.name }} 2>/dev/null || git clone --depth 1 git@github.com:${{ github.repository }}.git ~/${{ github.event.repository.name }} && cd ~/${{ github.event.repository.name }}
            git fetch --prune --depth=1 origin main
            git reset --hard origin/main
            docker compose -f compose.prod.yaml build --pull
            docker compose -f compose.prod.yaml up -d --remove-orphans
```

```yml
jobs:
  deploy:
```

해설 : 깃허브 액션이 할 일은 "deploy"라는 할 일이다.

```yml
runs-on: ubuntu-latest
```

해설 : 깃허브 액션의 호스트러너 라는 서버에서 최신 우분투 버전을 통해 "deploy"를 처리할거다.

```yml
steps:
```

해설 : "deploy"는 아래와 같은 단계를 거친다

```yml
uses: appleboy/ssh-action@v1.2.0
```

해설 : 이미 만들어진 Action(일종의 모듈)을 가져다가 쓸거다. 그 모듈의 이름은 "appleboy/ssh-action"이다. (직접 쉘을 실행하고 싶은 경우는 uses가 아니라 run을 사용합니다.)

```yml
with:
  host: ${{ secrets.VPS_HOST }}
  username: ${{ secrets.VPS_USER }}
  key: ${{ secrets.VPS_SSH_KEY }}
  script: |
```

해설 : appleboy/ssh-action에 host, username, key, script라는 파라미터를 넘겨줄거다. 이때 host, username, key는 GitHub 레포 → Settings → Secrets and variables → Actions의 repository secret에서 가져다가 쓸거다. 그래서 VPS로 접속해서 script를 실행할거다.

```yml
script: |
  set -e
  trap 'echo "Deploy failed at line $LINENO"' ERR
  cd ~/${{ github.event.repository.name }} 2>/dev/null || git clone --depth 1 git@github.com:${{ github.repository }}.git ~/${{ github.event.repository.name }} && cd ~/${{ github.event.repository.name }}
  git fetch --prune --depth=1 origin main
  git reset --hard origin/main
  docker compose -f compose.prod.yaml build --pull
  docker compose -f compose.prod.yaml up -d --remove-orphans
```

해설
` set -e` : 에러가 나면 중단함 - 가령 빌드를 했는데 에러가 나면 그 즉시 중단
`trap 'echo "Deploy failed at line $LINENO"' ERR` : 에러가 나면 에러가 발생한 줄 번호를 깃허브 액션 워크플로우 콘솔창에 띄워줄거다
`  cd ~/${{ github.event.repository.name }} 2>/dev/null || git clone --depth 1 git@github.com:${{ github.repository }}.git ~/${{ github.event.repository.name }} && cd ~/${{ github.event.repository.name }}` : VPS에서 폴더를 이동할건데, 폴더명은 레포지토리 이름이다. 레포지토리 이름으로 된 폴더명이 없으면 최신 커밋(`--depth 1`)만 클론 뜬다음에 폴더 만들어서 그 폴더로 이동할거다.
`  git fetch --prune --depth=1 origin main` : 폴더를 이동한 다음에 최신 커밋을 가져올거다. 그러면서 삭제된 내용 있으면 삭제할거다.(`--prune`)
`git reset --hard origin/main` : 최신 커밋으로 이동할거다.
`  docker compose -f compose.prod.yaml build --pull` : `compose.prod.yaml`와 함께(`-f compose.prod.yaml`) 도커 컴포즈로 실행할거다. (이때 원격 레지스트리에 있는 최신 도커파일을 있으면 불러올거다.(`--pull` (이 프로젝트에서는 주로 node 이미지를 최신으로 불러오게 됨)))
`  docker compose -f compose.prod.yaml up -d --remove-orphans` : 이제 빌드한 도커를 올릴거다. 로그는 백그라운드에서만 찍어라(`-d`). 기존 컨테이너들은 전부 치워버려라(`--remove-orphans`).
