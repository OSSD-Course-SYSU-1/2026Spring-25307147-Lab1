export interface DanmakuState {
  readonly enabled: boolean;
  readonly inputText: string;
  readonly fontSize: number;
  readonly opacity: number;
  readonly speed: number;
}

export function createDanmakuState(
  enabled: boolean = true,
  inputText: string = '',
  fontSize: number = 16,
  opacity: number = 1,
  speed: number = 1
): DanmakuState {
  return {
    enabled,
    inputText,
    fontSize,
    opacity,
    speed
  };
}
