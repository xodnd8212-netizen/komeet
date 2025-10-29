import React, { useEffect, useState } from 'react';
import { View, Text, FlatList, TextInput, Button } from 'react-native';
import { useQuery, useMutation } from 'react-query';
import axios from '../../api/axios';
import { z } from 'zod';

const messageSchema = z.object({
  content: z.string().min(1, 'Message cannot be empty'),
});

const ChatRoom = ({ route }) => {
  const { chatId } = route.params;
  const [newMessage, setNewMessage] = useState('');

  const { data: messages, refetch } = useQuery(['messages', chatId], () =>
    axios.get(`/chats/${chatId}/messages`).then(res => res.data)
  );

  const sendMessageMutation = useMutation(
    (message) => axios.post(`/chats/${chatId}/messages`, message),
    {
      onSuccess: () => {
        refetch();
        setNewMessage('');
      },
    }
  );

  const handleSendMessage = () => {
    const validationResult = messageSchema.safeParse({ content: newMessage });
    if (validationResult.success) {
      sendMessageMutation.mutate({ content: newMessage });
    } else {
      alert(validationResult.error.errors[0].message);
    }
  };

  return (
    <View style={{ flex: 1, padding: 16 }}>
      <FlatList
        data={messages}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={{ marginVertical: 4 }}>
            <Text>{item.sender}: {item.content}</Text>
          </View>
        )}
      />
      <TextInput
        value={newMessage}
        onChangeText={setNewMessage}
        placeholder="Type your message..."
        style={{ borderWidth: 1, borderColor: '#ccc', padding: 8, marginVertical: 8 }}
      />
      <Button title="Send" onPress={handleSendMessage} />
    </View>
  );
};

export default ChatRoom;