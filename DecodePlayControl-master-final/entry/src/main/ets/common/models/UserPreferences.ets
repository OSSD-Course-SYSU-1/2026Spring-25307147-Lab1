export interface UserPreferences {
  readonly defaultQuality: string;
  readonly defaultSpeed: number;
  readonly autoPlay: boolean;
  readonly rememberPosition: boolean;
  readonly danmakuEnabled: boolean;
}

export function createDefaultUserPreferences(): UserPreferences {
  return {
    defaultQuality: 'auto',
    defaultSpeed: 1,
    autoPlay: true,
    rememberPosition: true,
    danmakuEnabled: true
  };
}
