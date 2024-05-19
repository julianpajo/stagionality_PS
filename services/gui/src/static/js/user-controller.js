const cookieValue = getCookie('_oauth2_proxy');

const url = 'https://displacement.euler.local/oauth2/userinfo';

fetch(url, {
  method: 'GET',
  headers: {
    'Cookie': '_oauth2_proxy=' + cookieValue
  }
})
.then(response => {
  if (!response.ok) {
    throw new Error('Errore nella richiesta: ' + response.status);
  }
  return response.text();
})
.then(data => {

    const userData = JSON.parse(data);
    const preferredUsername = userData.preferredUsername;
    document.getElementById('user').textContent = preferredUsername;
    document.getElementById('user-menu').textContent = preferredUsername;
})
.catch(error => {
  console.error('Si è verificato un errore:', error);
});


function toggleMenu() {
    var menu = document.getElementById("menu");
    menu.classList.toggle("open-menu");
}


function performLogout() {
    var logoutUrl = 'https://displacement.euler.local/oauth2/sign_out';
    var redirectAfterLogout = 'https://displacement.euler.local';
    var keycloakRedirectUrl = 'https://keycloak.euler.local/auth/realms/Euler/protocol/openid-connect/logout?client_id=euler&post_logout_redirect_uri=' + encodeURIComponent(redirectAfterLogout);

    var fullLogoutUrl = logoutUrl + '?rd=' + encodeURIComponent(keycloakRedirectUrl);

    window.location.href = fullLogoutUrl;
}


function getCookie(name) {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) return parts.pop().split(';').shift();
}