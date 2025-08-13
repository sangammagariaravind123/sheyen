// Create a new file named script.js

window.addEventListener("load", function () {
  const loaderContainer = document.getElementById("loader-container");
  const mainContent = document.getElementById("main-content");

  // Hide loader and show content after 2 seconds
  setTimeout(function () {
    loaderContainer.style.display = "none";
    mainContent.style.display = "flex";
  }, 1500); // 1.5-second delay
});
