# Dockerfile 3개 분리 이유 설명

이 프로젝트에는 3개의 서로 다른 Dockerfile이 있습니다. 각각은 다른 목적과 환경에 최적화되어 있습니다.

## Dockerfile 목록

1. **`dev.Dockerfile`** - 개발 환경용
2. **`prod.Dockerfile`** - 프로덕션 환경용 (멀티스테이지 빌드)
3. **`prod-without-multistage.Dockerfile`** - 프로덕션 환경용 (단일 스테이지)

---

## 1. dev.Dockerfile (개발 환경)

### 목적

- 개발 중인 애플리케이션을 빠르게 실행하기 위한 최적화
- 핫 리로드(Hot Reload) 지원
- 볼륨 마운트를 통한 실시간 코드 변경 반영

### 주요 특징

```dockerfile
# 단일 스테이지 빌드
FROM node:18-alpine

# 개발 모드로 실행
CMD yarn dev  # 또는 npm run dev
```

### 변수명과 역할

**`WORKDIR /app`**

- 컨테이너 내부의 작업 디렉토리를 `/app`으로 설정
- 이후 모든 명령어가 이 디렉토리에서 실행됨

**`COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./`**

- 패키지 매니저별 lockfile을 복사
- `*` 와일드카드로 해당 파일이 없어도 에러 발생하지 않음
- 의존성 설치를 위한 파일들만 먼저 복사하여 Docker 레이어 캐싱 활용

**`RUN` 블록의 조건문**

```bash
if [ -f yarn.lock ]; then yarn --frozen-lockfile;
elif [ -f package-lock.json ]; then npm ci;
elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i;
else yarn install;
fi
```

- 프로젝트에서 사용하는 패키지 매니저를 자동 감지
- `--frozen-lockfile`: yarn에서 lockfile과 정확히 일치하는 버전만 설치
- `npm ci`: npm에서 lockfile 기반으로 빠른 설치

**`CMD` 블록**

- 컨테이너 실행 시 `yarn dev` 또는 `npm run dev` 명령어 실행
- Next.js 개발 서버를 핫 리로드 모드로 시작

---

## 2. prod.Dockerfile (멀티스테이지 빌드)

### 목적

- 프로덕션 배포를 위한 최적화된 이미지 생성
- 이미지 크기 최소화 (약 110MB)
- 보안 강화 (root 사용자 제거)

### 주요 특징

```dockerfile
# 1단계: 빌더 스테이지
FROM node:18-alpine AS builder
# 의존성 설치 및 빌드

# 2단계: 러너 스테이지
FROM node:18-alpine AS runner
# 최소한의 파일만 복사하여 실행
```

### 변수명과 역할

**`AS builder`**

- 첫 번째 스테이지의 이름을 `builder`로 지정
- 이 스테이지에서 의존성 설치와 빌드 작업 수행

**`AS runner`**

- 두 번째 스테이지의 이름을 `runner`로 지정
- 최종 실행 환경을 위한 스테이지

**`ARG ENV_VARIABLE` / `ENV ENV_VARIABLE=${ENV_VARIABLE}`**

- `ARG`: 빌드 시점에 전달받는 변수
- `ENV`: 런타임에 사용되는 환경변수
- 빌드 시점과 런타임 모두에서 환경변수 사용 가능

**`RUN addgroup --system --gid 1001 nodejs`**

- 시스템 그룹 `nodejs`를 GID 1001로 생성
- 보안을 위해 root가 아닌 일반 사용자로 실행하기 위함

**`RUN adduser --system --uid 1001 nextjs`**

- 시스템 사용자 `nextjs`를 UID 1001로 생성
- 애플리케이션을 실행할 전용 사용자

**`USER nextjs`**

- 이후 모든 명령어를 `nextjs` 사용자로 실행
- 보안 강화를 위한 권한 제한

**`COPY --from=builder /app/public ./public`**

- `builder` 스테이지에서 `public` 폴더만 복사
- 멀티스테이지 빌드의 핵심: 필요한 파일만 선택적 복사

**`COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./`**

- Next.js Output Standalone 기능으로 생성된 독립 실행 파일들 복사
- `--chown=nextjs:nodejs`: 파일 소유권을 nextjs 사용자와 nodejs 그룹으로 설정

**`COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static`**

- 정적 파일들만 복사
- 이미지 크기 최소화를 위해 필요한 파일만 선택

**`CMD ["node", "server.js"]**

- 배열 형태로 명령어 실행
- Next.js Output Standalone으로 생성된 `server.js` 실행

---

## 3. prod-without-multistage.Dockerfile (단일 스테이지)

### 목적

- 멀티스테이지 빌드 없이 프로덕션 환경 구축
- 단순한 구조로 이해하기 쉬움
- 기본적인 프로덕션 배포

### 주요 특징

```dockerfile
# 단일 스테이지 빌드
FROM node:18-alpine

# 빌드 후 바로 실행
CMD yarn start  # 또는 npm run start
```

### 변수명과 역할

**`COPY src ./src`**

- 소스 코드 전체를 컨테이너로 복사
- 개발 의존성과 프로덕션 의존성 모두 포함

**`RUN` 블록의 빌드 명령어**

```bash
if [ -f yarn.lock ]; then yarn build;
elif [ -f package-lock.json ]; then npm run build;
elif [ -f pnpm-lock.yaml ]; then pnpm build;
else npm run build;
fi
```

- Next.js 애플리케이션을 프로덕션용으로 빌드
- 정적 파일 생성 및 최적화 수행

**`CMD` 블록**

```bash
if [ -f yarn.lock ]; then yarn start;
elif [ -f package-lock.json ]; then npm run start;
elif [ -f pnpm-lock.yaml ]; then pnpm start;
else npm run start;
fi
```

- 빌드된 애플리케이션을 프로덕션 모드로 실행
- `next start` 명령어로 최적화된 서버 시작

---

## 비교표

| 구분            | dev.Dockerfile | prod.Dockerfile   | prod-without-multistage.Dockerfile |
| --------------- | -------------- | ----------------- | ---------------------------------- |
| **목적**        | 개발 환경      | 프로덕션 (최적화) | 프로덕션 (단순)                    |
| **이미지 크기** | ~1GB           | ~110MB            | ~1GB                               |
| **빌드 복잡도** | 낮음           | 높음              | 낮음                               |
| **실행 속도**   | 느림           | 빠름              | 보통                               |
| **핫 리로드**   | 지원           | 미지원            | 미지원                             |
| **보안**        | 보통           | 높음              | 낮음                               |
| **사용 시기**   | 개발 중        | 실제 배포         | 테스트 배포                        |

---

## 언제 어떤 것을 사용할까?

### 개발 중

```bash
docker compose -f compose.dev.yaml up
```

- **dev.Dockerfile** 사용
- 코드 변경 시 자동 반영
- 디버깅 도구 사용 가능

### 실제 프로덕션 배포

```bash
docker compose -f compose.prod.yaml up -d
```

- **prod.Dockerfile** 사용
- 최소한의 이미지 크기
- 최고의 성능과 보안

### 테스트 또는 학습용

```bash
docker compose -f compose.prod-without-multistage.yaml up -d
```

- **prod-without-multistage.Dockerfile** 사용
- 단순한 구조로 이해하기 쉬움
- 멀티스테이지 빌드 학습용

---

## 결론

3개의 Dockerfile은 서로 다른 목적을 가지고 있습니다:

1. **개발 효율성** (dev.Dockerfile)
2. **프로덕션 최적화** (prod.Dockerfile)
3. **단순함과 이해 용이성** (prod-without-multistage.Dockerfile)

각각의 변수명과 역할을 이해하고 상황에 맞게 선택하여 사용하시면 됩니다.
