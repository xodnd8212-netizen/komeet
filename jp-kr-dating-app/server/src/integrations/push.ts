import { Expo } from 'expo-server-sdk';

const expo = new Expo();

export const sendPushNotification = async (pushToken: string, message: string) => {
    if (!Expo.isExpoPushToken(pushToken)) {
        throw new Error(`Invalid push token: ${pushToken}`);
    }

    const messages = [{
        to: pushToken,
        sound: 'default',
        body: message,
        data: { message },
    }];

    try {
        const ticketChunk = await expo.sendPushNotificationsAsync(messages);
        return ticketChunk;
    } catch (error) {
        console.error('Error sending push notification:', error);
        throw new Error('Failed to send push notification');
    }
};