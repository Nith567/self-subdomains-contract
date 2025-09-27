import { NextRequest, NextResponse } from 'next/server';
import { MongoClient } from 'mongodb';

// MongoDB connection - replace with your connection string
const MONGODB_URI = process.env.MONGO_URI;
const DB_NAME = 'cryptonomads-bot';

let cachedClient: MongoClient | null = null;

async function connectToDatabase() {
  if (cachedClient) {
    return cachedClient;
  }
//@ts-ignore
  const client = new MongoClient(MONGODB_URI);
  await client.connect();
  cachedClient = client;
  return client;
}

export async function GET(
  request: NextRequest,
  { params }: { params: { uuid: string } }
) {
  try {
    const { uuid } = params;

    if (!uuid) {
      return NextResponse.json(
        { success: false, error: 'UUID is required' },
        { status: 400 }
      );
    }

    console.log(`🔍 Looking up user by UUID: ${uuid}`);

    // Connect to MongoDB
    const client = await connectToDatabase();
    const db = client.db(DB_NAME);
    const collection = db.collection('user_verifications'); // Fixed: Use correct collection name

    // Find user by verifyUuid
    const user = await collection.findOne({ verifyUuid: uuid });

    if (!user) {
      console.log(`❌ No verification session found for UUID: ${uuid}`);
      return NextResponse.json(
        { 
          success: false, 
          error: 'Invalid verification link',
          message: 'This verification session was not found. Please run /verify in Discord to get a new link.',
          code: 'SESSION_NOT_FOUND'
        },
        { status: 404 }
      );
    }

    console.log(`✅ Found user: ${user.username} (${user.userId})`);


    const userData = {
      discordUserId: user.userId,        // Database field: userId → Frontend: discordUserId
      username: user.username,
      walletAddress: user.walletAddress,
      guildId: user.guildId,
      verifyUuid: user.verifyUuid,
      verified: user.verified || false,
      onChainVerified: user.onChainVerified || false,
      country: user.selectedCountry || null, 
      gender: user.gender || null,
      isAdult: user.isAdult || null,          
      ensName: user.ensName || null,
      status: user.verified ? 'completed' : 'pending',
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      verifiedAt: user.verifiedAt
    };

    return NextResponse.json({
      success: true,
      data: userData
    });

  } catch (error) {
    console.error('❌ Error fetching user data:', error);
    return NextResponse.json(
      { success: false, error: 'Internal server error' },
      { status: 500 }
    );
  }
}


