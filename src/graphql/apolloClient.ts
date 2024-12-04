import { ApolloClient, InMemoryCache } from '@apollo/client';

const client = new ApolloClient({
  uri: 'http://your-graphql-endpoint', // Replace with your GraphQL endpoint
  cache: new InMemoryCache(),
});

export default client;
