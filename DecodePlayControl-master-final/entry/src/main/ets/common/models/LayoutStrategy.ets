import { BreakpointType } from './BreakpointType';

export interface Margin {
  readonly left: number;
  readonly right: number;
  readonly top: number;
  readonly bottom: number;
}

export interface Padding {
  readonly left: number;
  readonly right: number;
  readonly top: number;
  readonly bottom: number;
}

export interface ResponsiveStyle {
  readonly width?: number | string;
  readonly height?: number | string;
  readonly margin?: Margin;
  readonly padding?: Padding;
  readonly fontSize?: number;
  readonly lineHeight?: number;
}

export interface LayoutStrategy {
  readonly name: string;
  readonly applicableBreakpoints: BreakpointType[];
  readonly style: ResponsiveStyle;
  readonly priority: number;
}

export function createMargin(
  left: number = 0,
  right: number = 0,
  top: number = 0,
  bottom: number = 0
): Margin {
  return { left, right, top, bottom };
}

export function createPadding(
  left: number = 0,
  right: number = 0,
  top: number = 0,
  bottom: number = 0
): Padding {
  return { left, right, top, bottom };
}
