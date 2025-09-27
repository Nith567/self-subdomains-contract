// NextJS Page: app/verification/[uuid]/page.tsx
// This goes in your NextJS verification site

"use client";

import React, { useState, useEffect, useMemo } from "react";
import { useParams, useRouter } from "next/navigation";
import { countries, getUniversalLink } from "@selfxyz/core";
import {
  SelfQRcodeWrapper,
  SelfAppBuilder,
  type SelfApp,
} from "@selfxyz/qrcode";

// Types for user data
interface UserData {
  discordUserId: string;
  username: string;
  walletAddress: string;
  guildId: string;
  status: 'pending' | 'completed' | 'failed';
  verified: boolean;
  onChainVerified: boolean;
  country?: string;
  gender?: 'male' | 'female';
  isAdult?: boolean;
  ensName?: string;
}

export default function VerificationPage() {
  const params = useParams();
  const router = useRouter();
  const uuid = params.uuid as string;
  
  // State
  const [linkCopied, setLinkCopied] = useState(false);
  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState("");
  const [selfApp, setSelfApp] = useState<SelfApp | null>(null);
  const [universalLink, setUniversalLink] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // User data from Discord bot
  const [userData, setUserData] = useState<UserData | null>(null);
  
  const excludedCountries = useMemo(() => [countries.PAKISTAN], []);

  // Fetch user data by UUID
  useEffect(() => {
    const fetchUserData = async () => {
      if (!uuid) return;
      
      try {
        setLoading(true);
        const response = await fetch(`/api/user/${uuid}`);
        const data = await response.json();
        
        if (!data.success) {
          throw new Error(data.error || 'Failed to fetch user data');
        }
        
        setUserData(data.data);
        console.log('✅ User data loaded:', data.data);
        
      } catch (err) {
        console.error('❌ Error fetching user data:', err);
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, [uuid]);

  // Initialize Self Protocol app when user data is available
  useEffect(() => {
    if (!userData) return;
    
    try {
      const app = new SelfAppBuilder({
        version: 2,
        appName: process.env.NEXT_PUBLIC_SELF_APP_NAME || "CryptoNomads Verification",
        scope: process.env.NEXT_PUBLIC_SELF_SCOPE || "crypto-nomads",
        endpoint: process.env.NEXT_PUBLIC_SELF_ENDPOINT || "",
        chainID: 42220, // Celo mainnet
        logoBase64: "https://i.postimg.cc/mrmVf9hm/self.png",
        userId: userData.walletAddress, 
        endpointType: "celo",
        userIdType: "hex", // Ethereum address format
 userDefinedData: userData.discordUserId,
        disclosures: {
          minimumAge: 18,
          excludedCountries: excludedCountries,
          ofac: false,
          // what you want users to reveal
          // name: false,
          // issuing_state: true,
          nationality: true,
          gender: true,
        }
      }).build();

      setSelfApp(app);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      setUniversalLink(getUniversalLink(app as any));
      
      console.log('✅ Self Protocol app initialized with wallet:', userData.walletAddress);
      
    } catch (error) {
      console.error("❌ Failed to initialize Self app:", error);
      setError("Failed to initialize verification app");
    }
  }, [userData, excludedCountries, uuid]);

  const handleSuccessfulVerification = async (verificationData?: Record<string, unknown>) => {
    if (!userData || !uuid) return;
    
    try {
      displayToast("🎉 Verification successful! Updating Discord...");
      setTimeout(() => {
        router.push(`/verified`);
      }, 2000);
    } catch (error) {
      console.error('❌ Error updating verification:', error);
      displayToast("❌ Error updating verification. Please try again.");
    }
  };

  const displayToast = (message: string) => {
    setToastMessage(message);
    setShowToast(true);
    setTimeout(() => setShowToast(false), 4000);
  };

  const copyToClipboard = () => {
    if (!universalLink) return;

    navigator.clipboard
      .writeText(universalLink)
      .then(() => {
        setLinkCopied(true);
        displayToast("📋 Universal link copied to clipboard!");
        setTimeout(() => setLinkCopied(false), 2000);
      })
      .catch((err) => {
        console.error("Failed to copy text: ", err);
        displayToast("❌ Failed to copy link");
      });
  };

  const openSelfApp = () => {
    if (!universalLink) return;
    window.open(universalLink, "_blank");
    displayToast("📱 Opening Self App...");
  };

  // Loading state
  if (loading) {
    return (
      <div className="min-h-screen w-full bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading verification session...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error || !userData) {
    return (
      <div className="min-h-screen w-full bg-gray-50 flex items-center justify-center">
        <div className="text-center bg-white p-8 rounded-lg shadow-lg max-w-md">
          <div className="text-red-500 text-6xl mb-4">❌</div>
          <h2 className="text-xl font-bold text-gray-800 mb-2">Verification Error</h2>
          <p className="text-gray-600 mb-4">{error || "Invalid verification session"}</p>
          <button 
            onClick={() => window.location.href = '/'}
            className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
          >
            Go Home
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen w-full bg-gray-50 flex flex-col items-center justify-center p-4 sm:p-6 md:p-8">
      {/* Header with Discord Info */}
      <div className="mb-6 md:mb-8 text-center">
        <h1 className="text-2xl sm:text-3xl font-bold mb-2 text-gray-800">
          🔐 CryptoNomads Verification
        </h1>
        <div className="bg-white rounded-lg p-4 mb-4 shadow-sm">
          <p className="text-sm text-gray-600 mb-2">Verifying Discord User:</p>
          <p className="font-bold text-lg text-blue-600">@{userData.username}</p>
          <p className="text-xs text-gray-500 mt-1">ID: {userData.discordUserId}</p>
        </div>
        <p className="text-sm sm:text-base text-gray-600 px-2">
          Scan QR code with Self Protocol App to verify your identity
        </p>
      </div>

      {/* Main Verification Content */}
      <div className="bg-white rounded-xl shadow-lg p-4 sm:p-6 w-full max-w-xs sm:max-w-sm md:max-w-md mx-auto">
        <div className="flex justify-center mb-4 sm:mb-6">
          {selfApp ? (
            <SelfQRcodeWrapper
              selfApp={selfApp}
              onSuccess={handleSuccessfulVerification}
              onError={(error) => {
                console.error('Self Protocol error:', error);
                displayToast("❌ Verification failed. Please try again.");
              }}
            />
          ) : (
            <div className="w-[256px] h-[256px] bg-gray-200 animate-pulse flex items-center justify-center">
              <p className="text-gray-500 text-sm">Loading QR Code...</p>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-2 sm:space-x-2 mb-4 sm:mb-6">
          <button
            type="button"
            onClick={copyToClipboard}
            disabled={!universalLink}
            className="flex-1 bg-gray-800 hover:bg-gray-700 transition-colors text-white p-2 rounded-md text-sm sm:text-base disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {linkCopied ? "📋 Copied!" : "📋 Copy Link"}
          </button>

          <button
            type="button"
            onClick={openSelfApp}
            disabled={!universalLink}
            className="flex-1 bg-blue-600 hover:bg-blue-500 transition-colors text-white p-2 rounded-md text-sm sm:text-base mt-2 sm:mt-0 disabled:bg-blue-300 disabled:cursor-not-allowed"
          >
            📱 Open Self App
          </button>
        </div>

        {/* Wallet Address Display */}
        <div className="flex flex-col items-center gap-2 mt-2">
          <span className="text-gray-500 text-xs uppercase tracking-wide">
            🏦 Privy Wallet Address
          </span>
          <div className="bg-gray-100 rounded-md px-3 py-2 w-full text-center break-all text-sm font-mono text-gray-800 border border-gray-200">
            {userData.walletAddress}
          </div>
        </div>

        {/* Verification Status */}
        <div className="mt-4 p-3 bg-blue-50 rounded-lg">
          <div className="flex items-center justify-between text-sm">
            <span className="text-gray-600">Status:</span>
            <span className={`font-medium ${userData.verified ? 'text-green-600' : 'text-orange-600'}`}>
              {userData.verified ? '✅ Verified' : '⏳ Pending'}
            </span>
          </div>
          {userData.country && (
            <div className="flex items-center justify-between text-sm mt-1">
              <span className="text-gray-600">Country:</span>
              <span className="font-medium">{userData.country}</span>
            </div>
          )}
        </div>
      </div>

      {/* Toast Notification */}
      {showToast && (
        <div className="fixed bottom-4 right-4 bg-gray-800 text-white py-3 px-4 rounded-lg shadow-lg animate-fade-in text-sm max-w-sm">
          {toastMessage}
        </div>
      )}
    </div>
  );
}
