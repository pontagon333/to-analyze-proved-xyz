import { Auth, Hub } from "aws-amplify";
import { useState } from "react";
import { Connector } from "wagmi";

export const useAuth = () => {
  const [error, setError] = useState<Error | undefined>(undefined);
  const [loading, setLoading] = useState(false);

  const login = async (address: string, connector: Connector) => {
    setError(undefined);
    setLoading(true);
    try {
      if (!address.startsWith("0x")) {
        setError(new Error("No address"));
        return;
      }
      console.log('5555')
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_AUTH_API}/nonce?address=${address}`,
        {
          method: "GET",
        }
      );
      const json = await res.json();
      // 署名の要求
      const signer = await connector.getSigner();
      const signature = await signer.signMessage(`Proved nonce ${json.nonce}`);
      const body = JSON.stringify({
        address,
        signature: signature,
      });
      console.log("==== body", signature, body);
      const authResult = await fetch(
        `${process.env.NEXT_PUBLIC_AUTH_API}/auth`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Request-Headers": "*",
            "Access-Control-Request-Method": "*"
          },
          body,
        }
      );
      console.log('6666')
      const authJson = await authResult.json();
      console.log("==== authJson", authJson);
      await Auth.federatedSignIn(
        "developer",
        {
          identity_id: authJson.IdentityId,
          token: authJson.Token,
          expires_at: 3600 * 1000 + new Date().getTime(),
        },
        { name: address }
      );
      Hub.dispatch("user", { event: "register" });
    } catch (e: unknown) {
      console.log("===== error", e);
      setError(e as Error);
    } finally {
      setLoading(false);
    }
  };

  return [
    {
      error,
      loading,
    },
    login,
  ] as const;
};
