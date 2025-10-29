import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import SignIn from './screens/Auth/SignIn';
import SignUp from './screens/Auth/SignUp';
import EditProfile from './screens/Profile/EditProfile';
import MatchList from './screens/Matches/MatchList';
import ChatRoom from './screens/Chat/ChatRoom';

const Stack = createStackNavigator();

const App = () => {
  return (
    <NavigationContainer>
      <Stack.Navigator initialRouteName="SignIn">
        <Stack.Screen name="SignIn" component={SignIn} />
        <Stack.Screen name="SignUp" component={SignUp} />
        <Stack.Screen name="EditProfile" component={EditProfile} />
        <Stack.Screen name="MatchList" component={MatchList} />
        <Stack.Screen name="ChatRoom" component={ChatRoom} />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default App;