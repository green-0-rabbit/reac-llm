interface RuntimeConfig {
  API_URL?: string;
  SESSION_REPLAY_KEY?: string;
  PIANO_ANALYTICS_SITE_ID?: string;
  PIANO_ANALYTICS_COLLECTION_DOMAIN?: string;
}

export const getEnv = (key: keyof RuntimeConfig) => {
  const runtime = (window as any).RUNTIME_CONFIG as RuntimeConfig;
  return runtime?.[key] || import.meta.env[`VITE_${key}`];
};
