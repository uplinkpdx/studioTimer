document.addEventListener("DOMContentLoaded", function() {
    const toggleButton = document.getElementById('theme-toggle');
    const currentTheme = localStorage.getItem('theme') || 'dark';

    // Apply the saved theme on load
    if (currentTheme === 'light') {
        document.body.classList.add('light-theme');
        toggleButton.textContent = 'Switch to Dark Mode';
    }

    // Toggle the theme on button click
    toggleButton.addEventListener('click', () => {
        document.body.classList.toggle('light-theme');

        // Update button text
        const isLightTheme = document.body.classList.contains('light-theme');
        toggleButton.textContent = isLightTheme ? 'Dark Mode' : 'Light Mode';

        // Save the preference in localStorage
        localStorage.setItem('theme', isLightTheme ? 'light' : 'dark');
    });
});
