export interface VideoPlaybackState {
  readonly currentVideoIndex: number;
  readonly playbackPosition: number;
  readonly playbackSpeed: number;
  readonly volume: number;
  readonly isPlaying: boolean;
  readonly quality: string;
  readonly duration: number;
}

export function createVideoPlaybackState(
  currentVideoIndex: number = 0,
  playbackPosition: number = 0,
  playbackSpeed: number = 1,
  volume: number = 1,
  isPlaying: boolean = false,
  quality: string = 'auto',
  duration: number = 0
): VideoPlaybackState {
  return {
    currentVideoIndex,
    playbackPosition,
    playbackSpeed,
    volume,
    isPlaying,
    quality,
    duration
  };
}
