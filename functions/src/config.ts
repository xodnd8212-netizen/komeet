export type Platform = 'apple' | 'google' | 'web';

export interface CoinBundle {
  bundleId: string;
  title: string;
  coins: number;
  price: number;
  currency: string;
  bonusRate?: number; // 0.2 => 20%
}

export const COIN_BUNDLES: Record<string, CoinBundle> = {
  small: {
    bundleId: 'small',
    title: '100 Coins',
    coins: 100,
    price: 1000,
    currency: 'KRW',
    bonusRate: 0.2,
  },
  medium: {
    bundleId: 'medium',
    title: '500 Coins',
    coins: 500,
    price: 4500,
    currency: 'KRW',
    bonusRate: 0.2,
  },
  large: {
    bundleId: 'large',
    title: '1200 Coins',
    coins: 1200,
    price: 9000,
    currency: 'KRW',
    bonusRate: 0.2,
  },
};

export const ACTION_COSTS: Record<string, number> = {
  swipe_extra: 5,
  special_like: 10,
  super_like: 50,
  boost: 200,
  priority: 150,
};

export const SUBSCRIPTION_PLAN_ID = 'premium_monthly';
export const SUBSCRIPTION_DAILY_COINS = 25;
export const SUBSCRIPTION_WEEKLY_BOOST = 1;

export const FIRST_PURCHASE_BONUS_RATE = 0.2;
export const FREE_SIGNUP_SWIPES = 15;
export const PROFILE_COMPLETE_BONUS_COINS = 50;
