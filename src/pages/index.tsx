import Head from "next/head";
import Image from "next/image";
import styles from "../styles/Home.module.css";
import { GetStaticProps } from "next";

interface HomeProps {
  now: string;
  envVariable: string;
}

export default function Home({ now, envVariable }: HomeProps) {
  return (
    <div className={styles.container}>
      <Head>
        <title>Create Next app</title>
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={styles.main}>
        <h1 className={styles.title}>
          Welcome to <a href="https://nextjs.org">Next.js</a> on Docker Compose!
        </h1>
        <h1 className={styles.title}>자동 배포에 성공하셨군요!</h1>
        <div className={styles.card}>
          <h3>배포 성공시각</h3>
          <p>
            <strong>{now}</strong>
          </p>
          <h3>환경변수</h3>
          <p>
            <strong>ENV_VARIABLE (서버사이드):</strong> {envVariable}
          </p>
          <p>
            <strong>NEXT_PUBLIC_ENV_VARIABLE (클라이언트):</strong>{" "}
            {process.env.NEXT_PUBLIC_ENV_VARIABLE}
          </p>
        </div>

        <div className={styles.grid}>
          <a href="https://nextjs.org/docs" className={styles.card}>
            <h3>Documentation &rarr;</h3>
            <p>Find in-depth information about Next.js features and API.</p>
          </a>

          <a href="https://nextjs.org/learn" className={styles.card}>
            <h3>Learn &rarr;</h3>
            <p>Learn about Next.js in an interactive course with quizzes!</p>
          </a>

          <a
            href="https://github.com/vercel/next.js/tree/master/examples"
            className={styles.card}
          >
            <h3>Examples &rarr;</h3>
            <p>Discover and deploy boilerplate example Next.js projects.</p>
          </a>

          <a
            href="https://vercel.com/new?utm_source=create-next-app&utm_medium=default-template&utm_campaign=create-next-app"
            target="_blank"
            rel="noopener noreferrer"
            className={styles.card}
          >
            <h3>Deploy &rarr;</h3>
            <p>
              Instantly deploy your Next.js site to a public URL with Vercel.
            </p>
          </a>
        </div>
      </main>

      <footer className={styles.footer}>
        <a
          href="https://vercel.com?utm_source=create-next-app&utm_medium=default-template&utm_campaign=create-next-app"
          target="_blank"
          rel="noopener noreferrer"
        >
          Powered by{" "}
          <span className={styles.logo}>
            <Image src="/vercel.svg" alt="Vercel Logo" width={72} height={16} />
          </span>
        </a>
      </footer>
    </div>
  );
}

export const getStaticProps: GetStaticProps<HomeProps> = async () => {
  const now = new Date().toLocaleString();
  const envVariable =
    process.env.ENV_VARIABLE || "환경변수가 설정되지 않았습니다";

  return {
    props: {
      now,
      envVariable,
    },
  };
};
