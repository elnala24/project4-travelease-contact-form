// Replace with your actual API Gateway endpoint from `terraform output api_url`
const API_URL = "https://g8wkavqozj.execute-api.us-west-1.amazonaws.com/prod/submit";

const form = document.getElementById("contact-form");
const statusDiv = document.getElementById("form-status");
const submitBtn = form.querySelector(".btn-submit");

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  // Gather form data
  const name = document.getElementById("name").value.trim();
  const email = document.getElementById("email").value.trim();
  const message = document.getElementById("message").value.trim();

  // Disable button while request is in flight
  submitBtn.disabled = true;
  submitBtn.textContent = "Sending...";
  hideStatus();

  try {
    const response = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, email, message }),
    });

    const data = await response.json();

    if (response.ok) {
      showStatus(
        `Thank you, ${name}! Your inquiry (${data.inquiryId}) has been submitted. Check your email for a confirmation.`,
        "success"
      );
      form.reset();
    } else {
      showStatus(
        "Something went wrong. Please try again later.",
        "error"
      );
    }
  } catch (err) {
    console.error("Submission error:", err);
    showStatus(
      "Unable to reach the server. Please check your connection and try again.",
      "error"
    );
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = "Send Inquiry";
  }
});

function showStatus(message, type) {
  statusDiv.textContent = message;
  statusDiv.className = `form-status ${type}`;
  statusDiv.hidden = false;
}

function hideStatus() {
  statusDiv.hidden = true;
  statusDiv.className = "form-status";
}
