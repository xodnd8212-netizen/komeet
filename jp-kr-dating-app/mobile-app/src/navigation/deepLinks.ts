import { Linking } from 'react-native';

const handleDeepLink = (url: string) => {
  const route = url.replace(/.*?:\/\//g, '');
  
  switch (route) {
    case 'signin':
      // Navigate to SignIn screen
      break;
    case 'signup':
      // Navigate to SignUp screen
      break;
    case 'profile':
      // Navigate to Profile screen
      break;
    case 'matches':
      // Navigate to Matches screen
      break;
    case 'chat':
      // Navigate to Chat screen
      break;
    default:
      // Handle unknown routes
      break;
  }
};

const setupDeepLinking = () => {
  Linking.addEventListener('url', ({ url }) => {
    handleDeepLink(url);
  });

  // Handle the case when the app is opened from a closed state
  Linking.getInitialURL().then(url => {
    if (url) {
      handleDeepLink(url);
    }
  });
};

export { setupDeepLinking };