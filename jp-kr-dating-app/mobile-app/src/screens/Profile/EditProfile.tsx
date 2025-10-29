import React, { useEffect } from 'react';
import { View, Text, TextInput, Button, StyleSheet } from 'react-native';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useQuery, useMutation } from 'react-query';
import { updateUserProfile } from '../../api/axios'; // Adjust the import based on your API structure
import { useStore } from '../../store/zustand'; // Adjust the import based on your Zustand store setup

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email address'),
  bio: z.string().optional(),
});

const EditProfile = () => {
  const { user } = useStore(); // Get user data from Zustand store
  const { register, handleSubmit, setValue } = useForm({
    resolver: zodResolver(schema),
  });

  useEffect(() => {
    if (user) {
      setValue('name', user.name);
      setValue('email', user.email);
      setValue('bio', user.bio);
    }
  }, [user, setValue]);

  const mutation = useMutation(updateUserProfile, {
    onSuccess: () => {
      // Handle success (e.g., show a success message or redirect)
    },
    onError: (error) => {
      // Handle error (e.g., show an error message)
      console.error(error);
    },
  });

  const onSubmit = (data) => {
    mutation.mutate(data);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Edit Profile</Text>
      <TextInput
        style={styles.input}
        placeholder="Name"
        {...register('name')}
      />
      <TextInput
        style={styles.input}
        placeholder="Email"
        keyboardType="email-address"
        {...register('email')}
      />
      <TextInput
        style={styles.input}
        placeholder="Bio"
        multiline
        {...register('bio')}
      />
      <Button title="Save Changes" onPress={handleSubmit(onSubmit)} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  title: {
    fontSize: 24,
    marginBottom: 16,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 4,
    padding: 8,
    marginBottom: 16,
  },
});

export default EditProfile;