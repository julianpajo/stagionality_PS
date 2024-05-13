const cookieValue = getCookie('_oauth2_proxy');

function getCookie(name) {
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) return parts.pop().split(';').shift();
}

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

})
.catch(error => {
  console.error('Si è verificato un errore:', error);
});
