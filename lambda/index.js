// Imports - bring in the tools we need
const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");
const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");

// Initialization - create connections to AWS services
const dynamoDB = new DynamoDBClient({});
const ses = new SESClient({});

exports.handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { name, email, message } = body;

    // Generate unique ID
    const inquiryId = `INQ-${Date.now()}`;

    // Save to DynamoDB
    await dynamoDB.send(new PutItemCommand({
      TableName: process.env.TABLE_NAME,
      Item: {
        inquiry_id: { S: inquiryId },
        name: { S: name },
        email: { S: email },
        message: { S: message },
        timestamp: { S: new Date().toISOString() }
      }
    }));

    // Send confirmation email to customer
    await ses.send(new SendEmailCommand({
      Source: process.env.SENDER_EMAIL,
      Destination: { ToAddresses: [email] },
      Message: {
        Subject: { Data: "TravelEase - We received your inquiry!" },
        Body: {
          Text: { Data: `Hi ${name},\n\nThank you for contacting TravelEase! Your inquiry ID is ${inquiryId}.\n\nWe'll get back to you soon.\n\nBest regards,\nTravelEase Team` }
        }
      }
    }));

    // Send notification to business
    await ses.send(new SendEmailCommand({
      Source: process.env.SENDER_EMAIL,
      Destination: { ToAddresses: [process.env.BUSINESS_EMAIL] },
      Message: {
        Subject: { Data: `New Inquiry: ${inquiryId}` },
        Body: {
          Text: { Data: `New inquiry received!\n\nID: ${inquiryId}\nName: ${name}\nEmail: ${email}\nMessage: ${message}` }
        }
      }
    }));

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type"
      },
      body: JSON.stringify({ message: "Success!", inquiryId })
    };

  } catch (error) {
    console.error("Error:", error);
    return {
      statusCode: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type"
      },
      body: JSON.stringify({ message: "Error submitting inquiry" })
    };
  }
};