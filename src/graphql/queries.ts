import { gql } from '@apollo/client';

export const VERIFY_CREDENTIAL = gql`
  query VerifyCredential($credentialData: String!) {
    verifyCredential(credentialData: $credentialData) {
      valid
      message
    }
  }
`;
