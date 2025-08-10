# 소개

https://github.com/vercel/next.js/tree/canary/examples/with-docker-compose

1. 위 레포를 번역하였음.
2. 위 레포를 토대로 배포 자동화에 필요한 sh파일이나 GitHub Actions 설정을 추가하고 이에 대한 마크다운들을 추가함.

# Docker Compose와 함께하는 Next.js

이 예제는 Docker Compose를 사용하여 Next.js 개발 및 프로덕션 환경을 구축하고 실행하는 데 필요한 모든 것을 포함합니다.

## Docker Compose의 장점

- Node.js나 TypeScript 설치 없이 로컬에서 개발 ✨
- macOS, Windows, Linux 팀 간 일관된 개발 환경으로 쉬운 실행
- 단일 배포에서 여러 Next.js 앱, 데이터베이스, 기타 마이크로서비스 실행
- [Output Standalone](https://nextjs.org/docs/advanced-features/output-file-tracing#automatically-copying-traced-files)과 결합된 멀티스테이지 빌드로 최대 85% 작은 앱 (create-next-app의 1GB 대비 약 110MB)
- YAML 파일로 쉬운 설정

## 사용 방법

[npm](https://docs.npmjs.com/cli/init), [Yarn](https://yarnpkg.com/lang/en/docs/cli/create/), 또는 [pnpm](https://pnpm.io)을 사용하여 [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app)을 실행하여 예제를 부트스트랩하세요:

```bash
npx create-next-app --example with-docker-compose with-docker-compose-app
```

```bash
yarn create next-app --example with-docker-compose with-docker-compose-app
```

```bash
pnpm create next-app --example with-docker-compose with-docker-compose-app
```

설치가 완료된 후 선택적으로:

- `npm install` 또는 `yarn install` 또는 `pnpm install`을 실행하여 lockfile을 생성하세요.

버전 관리에 lockfile을 커밋하는 것을 권장합니다. 예제는 lockfile 없이도 작동하지만, 모든 의존성의 최신 버전을 사용할 때 빌드 오류가 발생할 가능성이 높습니다. 이렇게 하면 개발 및 프로덕션에서 항상 알려진 좋은 구성을 사용하게 됩니다.

## 사전 요구사항

Mac, Windows 또는 Linux용 [Docker Desktop](https://docs.docker.com/get-docker)을 설치하세요. Docker Desktop에는 Docker Compose가 설치의 일부로 포함되어 있습니다.

## 개발

먼저 개발 서버를 실행하세요:

```bash
# 컨테이너가 컨테이너 이름을 호스트명으로 사용하여 서로 통신할 수 있도록 네트워크 생성
docker network create my_network

# 개발 빌드
docker compose -f compose.dev.yaml build

# 개발 서버 실행
docker compose -f compose.dev.yaml up
```

브라우저에서 [http://localhost:3000](http://localhost:3000)을 열어 결과를 확인하세요.

`pages/index.tsx` 파일을 수정하여 페이지를 편집할 수 있습니다. 파일을 편집하면 페이지가 자동으로 업데이트됩니다.

## 프로덕션

프로덕션에서는 멀티스테이지 빌드를 강력히 권장합니다. Next [Output Standalone](https://nextjs.org/docs/advanced-features/output-file-tracing#automatically-copying-traced-files) 기능과 결합하면 프로덕션에 필요한 `node_modules` 파일만 최종 Docker 이미지에 복사됩니다.

먼저 프로덕션 서버를 실행하세요 (최종 이미지 약 110MB).

```bash
# 컨테이너가 컨테이너 이름을 호스트명으로 사용하여 서로 통신할 수 있도록 네트워크 생성
docker network create my_network

# 프로덕션 빌드
docker compose -f compose.prod.yaml build

# 백그라운드에서 프로덕션 서버 실행
docker compose -f compose.prod.yaml up -d
```

또는 멀티스테이지 빌드 없이 프로덕션 서버를 실행하세요 (최종 이미지 약 1GB).

```bash
# 컨테이너가 컨테이너 이름을 호스트명으로 사용하여 서로 통신할 수 있도록 네트워크 생성
docker network create my_network

# 멀티스테이지 없이 프로덕션 빌드
docker compose -f compose.prod-without-multistage.yaml build

# 백그라운드에서 멀티스테이지 없이 프로덕션 서버 실행
docker compose -f compose.prod-without-multistage.yaml up -d
```

[http://localhost:3000](http://localhost:3000)을 열어보세요.

## 유용한 명령어

```bash
# 실행 중인 모든 컨테이너 중지
docker kill $(docker ps -aq) && docker rm $(docker ps -aq)

# 공간 정리
docker system prune -af --volumes
```
