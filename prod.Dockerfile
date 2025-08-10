# Dockerfile 문법 버전 지정
# syntax=docker.io/docker/dockerfile:1

# 기본 이미지 정의: Node.js 20 버전의 Alpine Linux 사용
# Alpine Linux는 매우 작은 크기의 Linux 배포판입니다 (약 5MB)
FROM node:20-alpine AS base

# 1단계: 소스 코드 빌드 스테이지
# 이 스테이지에서는 의존성 설치와 애플리케이션 빌드를 수행합니다
FROM base AS builder

# 컨테이너 내부의 작업 디렉토리를 /app으로 설정
WORKDIR /app

# 패키지 매니저 파일들을 먼저 복사 (Docker 레이어 캐싱을 위한 최적화)
# yarn.lock*, package-lock.json*, pnpm-lock.yaml*: 각 패키지 매니저의 lockfile
# .npmrc*: npm 설정 파일
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./

# TypeScript 개발 의존성을 위해 --production 플래그를 생략
# 프로젝트에서 사용하는 패키지 매니저를 자동으로 감지하여 의존성 설치
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i; \
  # lockfile이 없어도 설치가 가능하도록 fallback 설정
  else echo "Warning: Lockfile not found. It is recommended to commit lockfiles to version control." && yarn install; \
  fi

# 애플리케이션 소스 코드와 설정 파일들을 복사
COPY src ./src
COPY public ./public
COPY next.config.js .
COPY tsconfig.json .

# 환경변수는 빌드 시점에 반드시 존재해야 합니다
# Next.js에서 빌드 시점에 환경변수를 사용하기 때문입니다
# https://github.com/vercel/next.js/discussions/14030
ARG ENV_VARIABLE
ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_ENV_VARIABLE
ENV NEXT_PUBLIC_ENV_VARIABLE=${NEXT_PUBLIC_ENV_VARIABLE}

# Next.js는 완전히 익명의 텔레메트리 데이터를 수집합니다
# https://nextjs.org/telemetry 에서 자세한 내용을 확인할 수 있습니다
# 다음 줄의 주석을 해제하면 빌드 시점에 텔레메트리를 비활성화할 수 있습니다
# ENV NEXT_TELEMETRY_DISABLED 1

# 프로젝트에서 사용하는 패키지 매니저를 자동으로 감지하여 Next.js 빌드 실행
RUN \
  if [ -f yarn.lock ]; then yarn build; \
  elif [ -f package-lock.json ]; then npm run build; \
  elif [ -f pnpm-lock.yaml ]; then pnpm build; \
  else npm run build; \
  fi

# 참고: 여기서 node_modules의 전체 복사본을 만드는 중간 단계를 추가할 필요는 없습니다
# Next.js의 Output Standalone 기능이 필요한 파일들만 자동으로 추적합니다

# 2단계: 프로덕션 실행 이미지, 필요한 파일들만 복사하여 실행
FROM base AS runner

# 컨테이너 내부의 작업 디렉토리를 /app으로 설정
WORKDIR /app

# 보안을 위해 root 사용자로 실행하지 않습니다
# 시스템 그룹과 사용자를 생성하여 제한된 권한으로 애플리케이션을 실행합니다
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# 빌더 스테이지에서 public 폴더만 복사
COPY --from=builder /app/public ./public

# Next.js Output Standalone 기능을 활용하여 이미지 크기를 자동으로 줄입니다
# https://nextjs.org/docs/advanced-features/output-file-tracing
# --chown=nextjs:nodejs: 파일의 소유권을 nextjs 사용자와 nodejs 그룹으로 설정
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# 런타임에서도 환경변수를 다시 정의해야 합니다
# ARG와 ENV를 사용하여 빌드 시점과 런타임 모두에서 환경변수 사용 가능
ARG ENV_VARIABLE
ENV ENV_VARIABLE=${ENV_VARIABLE}
ARG NEXT_PUBLIC_ENV_VARIABLE
ENV NEXT_PUBLIC_ENV_VARIABLE=${NEXT_PUBLIC_ENV_VARIABLE}

# 다음 줄의 주석을 해제하면 런타임에 텔레메트리를 비활성화할 수 있습니다
# ENV NEXT_TELEMETRY_DISABLED 1

# 참고: 여기서 포트를 노출하지 않습니다. Docker Compose가 포트 매핑을 처리합니다

# Next.js Output Standalone으로 생성된 server.js 파일을 실행
# 배열 형태로 명령어를 실행하여 셸 해석 없이 직접 실행합니다
CMD ["node", "server.js"]
