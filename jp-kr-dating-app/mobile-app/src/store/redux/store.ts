import { configureStore } from '@reduxjs/toolkit';
import { createSlice } from '@reduxjs/toolkit';

// Example slice for user authentication
const authSlice = createSlice({
  name: 'auth',
  initialState: {
    user: null,
    isAuthenticated: false,
  },
  reducers: {
    login(state, action) {
      state.user = action.payload;
      state.isAuthenticated = true;
    },
    logout(state) {
      state.user = null;
      state.isAuthenticated = false;
    },
  },
});

// Example slice for matches
const matchSlice = createSlice({
  name: 'matches',
  initialState: {
    matchList: [],
  },
  reducers: {
    setMatches(state, action) {
      state.matchList = action.payload;
    },
  },
});

// Configure the Redux store
const store = configureStore({
  reducer: {
    auth: authSlice.reducer,
    matches: matchSlice.reducer,
  },
});

// Export actions and store
export const { login, logout } = authSlice.actions;
export const { setMatches } = matchSlice.actions;
export default store;