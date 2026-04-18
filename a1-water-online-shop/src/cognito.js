const poolData = {
  UserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
  ClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
}

function assertCognitoConfig() {
  if (!poolData.UserPoolId || !poolData.ClientId) {
    throw new Error(
      'Cognito configuration is missing. Set VITE_COGNITO_USER_POOL_ID and VITE_COGNITO_CLIENT_ID in your Vite environment file.',
    )
  }
}

let cognitoModulePromise

function loadCognitoModule() {
  if (!cognitoModulePromise) {
    cognitoModulePromise = import('amazon-cognito-identity-js')
  }
  return cognitoModulePromise
}

async function createUserPool() {
  assertCognitoConfig()
  const { CognitoUserPool } = await loadCognitoModule()
  return new CognitoUserPool(poolData)
}

async function createCognitoUser(email) {
  const [{ CognitoUser }, userPool] = await Promise.all([
    loadCognitoModule(),
    createUserPool(),
  ])

  return new CognitoUser({
    Username: email,
    Pool: userPool,
  })
}

export async function getCurrentCognitoUser() {
  const userPool = await createUserPool()
  return userPool.getCurrentUser()
}

export async function getCurrentSession() {
  const cognitoUser = await getCurrentCognitoUser()
  if (!cognitoUser) return null

  return new Promise((resolve, reject) => {
    cognitoUser.getSession((err, session) => {
      if (err) {
        reject(err)
        return
      }

      resolve(
        session?.isValid()
          ? {
              uid: session.getIdToken().payload.sub,
              email: session.getIdToken().payload.email || cognitoUser.getUsername(),
              displayName: session.getIdToken().payload.email || cognitoUser.getUsername(),
            }
          : null,
      )
    })
  })
}

export async function signInWithCognito(email, password) {
  const normalizedEmail = String(email || '').trim()
  const [{ AuthenticationDetails }, cognitoUser] = await Promise.all([
    loadCognitoModule(),
    createCognitoUser(normalizedEmail),
  ])

  const authDetails = new AuthenticationDetails({
    Username: normalizedEmail,
    Password: password,
  })

  return new Promise((resolve, reject) => {
    cognitoUser.authenticateUser(authDetails, {
      onSuccess: (session) => {
        const payload = session?.getIdToken()?.payload || {}
        resolve({
          uid: payload.sub || '',
          email: payload.email || normalizedEmail,
          displayName: payload.email || normalizedEmail,
        })
      },
      onFailure: reject,
    })
  })
}

export async function signUpWithCognito(email, password) {
  const normalizedEmail = String(email || '').trim()
  const [{ CognitoUserAttribute }, userPool] = await Promise.all([
    loadCognitoModule(),
    createUserPool(),
  ])

  const attributes = [
    new CognitoUserAttribute({
      Name: 'email',
      Value: normalizedEmail,
    }),
  ]

  return new Promise((resolve, reject) => {
    userPool.signUp(normalizedEmail, password, attributes, [], (err, result) => {
      if (err) {
        reject(err)
        return
      }

      resolve({
        uid: result?.userSub || '',
        email: normalizedEmail,
        displayName: normalizedEmail,
        confirmed: result?.userConfirmed === true,
      })
    })
  })
}

export async function confirmSignUpWithCognito(email, code) {
  const cognitoUser = await createCognitoUser(String(email || '').trim())

  return new Promise((resolve, reject) => {
    cognitoUser.confirmRegistration(code, true, (err, result) => {
      if (err) {
        reject(err)
        return
      }

      resolve(result)
    })
  })
}

export async function resendConfirmationCode(email) {
  const cognitoUser = await createCognitoUser(String(email || '').trim())

  return new Promise((resolve, reject) => {
    cognitoUser.resendConfirmationCode((err, result) => {
      if (err) {
        reject(err)
        return
      }

      resolve(result)
    })
  })
}

export async function signOutFromCognito() {
  const cognitoUser = await getCurrentCognitoUser()
  if (cognitoUser) {
    cognitoUser.signOut()
  }
}
