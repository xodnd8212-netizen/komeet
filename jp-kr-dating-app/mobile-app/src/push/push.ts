import { Platform } from 'react-native';
import PushNotification from 'react-native-push-notification';

const configurePushNotifications = () => {
  PushNotification.configure({
    onNotification: function(notification) {
      console.log('Notification received: ', notification);
    },
    requestPermissions: Platform.OS === 'ios',
  });
};

const scheduleNotification = (title, message, date) => {
  PushNotification.localNotificationSchedule({
    title: title,
    message: message,
    date: date,
  });
};

const cancelAllNotifications = () => {
  PushNotification.cancelAllLocalNotifications();
};

export { configurePushNotifications, scheduleNotification, cancelAllNotifications };