const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({
    origin: process.env.NODE_ENV === 'production'
        ? ['https://seudominio.com'] // 👈 RESTRINJA EM PRODUÇÃO
        : true
});

admin.initializeApp();

// ✅ CONFIGURAÇÕES DE SEGURANÇA AVANÇADAS
const SECURITY_CONFIG = {
    maxPasswordLength: 100,
    minPasswordLength: 8, // 👈 AUMENTE PARA 8
    maxNameLength: 100,
    maxEmailLength: 100,
    maxPhoneLength: 20,
    maxRequestsPerMinute: 10, // 👈 RATE LIMITING
    allowedAdminDomains: ['@empresa.com'], // 👈 RESTRINJA DOMÍNIOS
};

// ✅ CACHE PARA RATE LIMITING
const requestCache = new Map();

// ✅ MIDDLEWARE DE SEGURANÇA
const securityMiddleware = async (req, res, next) => {
    const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
    const now = Date.now();
    const windowMs = 60000; // 1 minuto

    // Rate Limiting
    if (!requestCache.has(clientIp)) {
        requestCache.set(clientIp, []);
    }

    const requests = requestCache.get(clientIp).filter(time => time > now - windowMs);
    requestCache.set(clientIp, requests);

    if (requests.length >= SECURITY_CONFIG.maxRequestsPerMinute) {
        console.warn(`🚨 Rate limiting bloqueado: ${clientIp}`);
        return res.status(429).json({
            error: "Muitas requisições. Tente novamente em 1 minuto."
        });
    }

    requests.push(now);
    next();
};

// ✅ VALIDAÇÃO DE DOMÍNIO (SE APLICÁVEL)
const isValidAdminDomain = (email) => {
    if (SECURITY_CONFIG.allowedAdminDomains.length === 0) return true;

    return SECURITY_CONFIG.allowedAdminDomains.some(domain =>
        email.toLowerCase().endsWith(domain.toLowerCase())
    );
};

// ✅ SANITIZAÇÃO DE DADOS
const sanitizeInput = (input, maxLength) => {
    if (typeof input !== 'string') return '';

    // Remove caracteres potencialmente perigosos
    return input
        .slice(0, maxLength)
        .replace(/[<>]/g, '') // Remove < e >
        .trim();
};

// ✅ VALIDAÇÃO DE PERFIL
const isValidProfile = (perfil) => {
    if (!perfil || typeof perfil !== 'object') return false;

    const requiredFields = ['id', 'nome', 'permissoes'];
    return requiredFields.every(field => perfil[field] !== undefined);
};

// ✅ FUNÇÃO PRINCIPAL: Criar usuário completo (VERSÃO SEGURA)
exports.criarUsuarioCompleto = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        // 👈 ADICIONE O MIDDLEWARE
        await securityMiddleware(req, res, async () => {
            console.log('🎯 [FUNCTION] criarUsuarioCompleto chamada');

            try {
                // 1. Verificar método
                if (req.method !== "POST") {
                    return res.status(405).json({ error: "Método não permitido" });
                }

                // 2. Validar Content-Type
                if (!req.headers['content-type']?.includes('application/json')) {
                    return res.status(400).json({ error: "Content-Type deve ser application/json" });
                }

                // 3. Validar token
                const authHeader = req.headers.authorization || "";
                const idToken = authHeader.startsWith("Bearer ") ?
                    authHeader.substring(7) : null;

                if (!idToken) {
                    return res.status(401).json({ error: "Token não fornecido" });
                }

                let decodedToken;
                try {
                    decodedToken = await admin.auth().verifyIdToken(idToken);
                } catch (tokenError) {
                    console.warn('❌ Token inválido:', tokenError.message);
                    return res.status(401).json({ error: "Token inválido ou expirado" });
                }

                const uid = decodedToken.uid;

                // 4. Verificar se é admin
                let userDoc;
                try {
                    userDoc = await admin.firestore()
                        .collection("usuarios")
                        .doc(uid)
                        .get();
                } catch (firestoreError) {
                    console.error('❌ Erro no Firestore:', firestoreError);
                    return res.status(500).json({ error: "Erro interno do servidor" });
                }

                if (!userDoc.exists || !userDoc.data().isAdmin) {
                    console.warn(`🚨 Tentativa de acesso não autorizado: ${uid}`);
                    return res.status(403).json({ error: "Acesso negado - apenas administradores" });
                }

                // 5. Validar e sanitizar dados
                const { email, senha, nome, telefone, perfil, isAdmin = false } = req.body;

                // Validações obrigatórias
                if (!email || !senha || !nome || !perfil) {
                    return res.status(400).json({ error: "Dados incompletos" });
                }

                // Sanitização
                const sanitizedEmail = sanitizeInput(email, SECURITY_CONFIG.maxEmailLength).toLowerCase();
                const sanitizedNome = sanitizeInput(nome, SECURITY_CONFIG.maxNameLength);
                const sanitizedTelefone = telefone ? sanitizeInput(telefone, SECURITY_CONFIG.maxPhoneLength) : null;

                if (!isValidEmail(sanitizedEmail)) {
                    return res.status(400).json({ error: "E-mail inválido" });
                }

                if (!isValidPassword(senha)) {
                    return res.status(400).json({
                        error: `Senha deve ter entre ${SECURITY_CONFIG.minPasswordLength} e ${SECURITY_CONFIG.maxPasswordLength} caracteres`
                    });
                }

                // 👈 VALIDAÇÃO DE DOMÍNIO (OPCIONAL)
                if (isAdmin && !isValidAdminDomain(sanitizedEmail)) {
                    return res.status(400).json({
                        error: "Domínio de e-mail não permitido para administradores"
                    });
                }

                if (!isValidProfile(perfil)) {
                    return res.status(400).json({ error: "Perfil inválido" });
                }

                // 6. Verificar se email existe
                try {
                    await admin.auth().getUserByEmail(sanitizedEmail);
                    return res.status(400).json({ error: "E-mail já cadastrado" });
                } catch (error) {
                    // Email não existe, pode continuar
                }

                // 7. Criar usuário no Auth
                let userRecord;
                try {
                    userRecord = await admin.auth().createUser({
                        email: sanitizedEmail,
                        password: senha,
                        displayName: sanitizedNome,
                        phoneNumber: sanitizedTelefone || undefined,
                        disabled: false,
                        emailVerified: false,
                    });
                    console.log('✅ Usuário criado no Auth:', userRecord.uid);
                } catch (error) {
                    console.error('❌ Erro ao criar no Auth:', error);

                    // 👈 ERROS ESPECÍFICOS DO AUTH
                    if (error.code === 'auth/email-already-exists') {
                        return res.status(400).json({ error: "E-mail já cadastrado" });
                    }
                    if (error.code === 'auth/invalid-email') {
                        return res.status(400).json({ error: "E-mail inválido" });
                    }
                    if (error.code === 'auth/weak-password') {
                        return res.status(400).json({ error: "Senha muito fraca" });
                    }

                    return res.status(400).json({ error: "Erro ao criar usuário" });
                }

                // 8. Salvar no Firestore com transaction
                const db = admin.firestore();
                try {
                    await db.runTransaction(async (transaction) => {
                        const userRef = db.collection("usuarios").doc(userRecord.uid);

                        // Verificar se não foi criado por outra operação
                        const userSnapshot = await transaction.get(userRef);
                        if (userSnapshot.exists) {
                            throw new Error("Usuário já existe no Firestore");
                        }

                        const usuarioData = {
                            id: userRecord.uid,
                            nome: sanitizedNome,
                            email: sanitizedEmail,
                            telefone: sanitizedTelefone,
                            perfil: {
                                id: sanitizeInput(perfil.id, 50),
                                nome: sanitizeInput(perfil.nome, 100),
                                descricao: sanitizeInput(perfil.descricao || '', 200),
                                permissoes: Array.isArray(perfil.permissoes) ? perfil.permissoes : [],
                                ativo: perfil.ativo !== false,
                            },
                            dataCriacao: admin.firestore.FieldValue.serverTimestamp(),
                            ativo: true,
                            emailVerificado: false,
                            isAdmin: Boolean(isAdmin),
                            temSenhaDefinida: true,
                            criadoPor: uid,
                            // 👈 AUDITORIA
                            criadoEm: admin.firestore.FieldValue.serverTimestamp(),
                            ipCriacao: req.headers['x-forwarded-for'] || req.connection.remoteAddress,
                        };

                        transaction.set(userRef, usuarioData);
                    });

                    console.log('✅ Usuário salvo no Firestore');

                } catch (error) {
                    // 👈 COMPENSAÇÃO ROBUSTA
                    console.error('❌ Erro no Firestore, revertendo criação no Auth...');
                    try {
                        await admin.auth().deleteUser(userRecord.uid);
                        console.log('✅ Usuário removido do Auth (compensação)');
                    } catch (deleteError) {
                        console.error('❌ Erro na compensação:', deleteError);
                    }
                    throw error;
                }

                // 👈 LOG DE AUDITORIA
                try {
                    await db.collection("auditoria").add({
                        acao: "USUARIO_CRIADO",
                        usuarioId: userRecord.uid,
                        executadoPor: uid,
                        timestamp: admin.firestore.FieldValue.serverTimestamp(),
                        ip: req.headers['x-forwarded-for'] || req.connection.remoteAddress,
                        userAgent: req.headers['user-agent'],
                    });
                } catch (auditError) {
                    console.error('❌ Erro no log de auditoria:', auditError);
                    // Não falha a operação principal por erro de auditoria
                }

                // 9. Retornar sucesso (SEM DADOS SENSÍVEIS)
                res.status(200).json({
                    success: true,
                    userId: userRecord.uid,
                    message: "Usuário criado com sucesso!",
                    data: {
                        id: userRecord.uid,
                        email: userRecord.email,
                        nome: userRecord.displayName,
                    }
                });

            } catch (error) {
                console.error('💥 Erro geral:', error);

                // 👈 NUNCA EXPOR DETALHES INTERNOS
                res.status(500).json({
                    error: "Erro interno do servidor",
                    reference: `ERR_${Date.now()}` // ID para debug interno
                });
            }
        });
    });
});

// ✅ FUNÇÃO: Alterar senha (VERSÃO SEGURA)
exports.alterarSenhaUsuario = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        await securityMiddleware(req, res, async () => {
            console.log('🎯 [FUNCTION] alterarSenhaUsuario chamada');

            try {
                if (req.method !== "POST") {
                    return res.status(405).json({ error: "Método não permitido" });
                }

                if (!req.headers['content-type']?.includes('application/json')) {
                    return res.status(400).json({ error: "Content-Type deve ser application/json" });
                }

                const authHeader = req.headers.authorization || "";
                const idToken = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : null;

                if (!idToken) {
                    return res.status(401).json({ error: "Token não fornecido" });
                }

                const decodedToken = await admin.auth().verifyIdToken(idToken);
                const uid = decodedToken.uid;

                // Verificar se é admin
                const userDoc = await admin.firestore().collection("usuarios").doc(uid).get();
                if (!userDoc.exists || !userDoc.data().isAdmin) {
                    console.warn(`🚨 Tentativa de alterar senha não autorizada: ${uid}`);
                    return res.status(403).json({ error: "Acesso negado" });
                }

                const { userId, novaSenha } = req.body;

                if (!userId || !novaSenha) {
                    return res.status(400).json({ error: "Dados incompletos" });
                }

                if (!isValidPassword(novaSenha)) {
                    return res.status(400).json({ error: "Senha deve ter pelo menos 6 caracteres" });
                }

                // 👈 VERIFICAR SE USUÁRIO EXISTE
                try {
                    await admin.auth().getUser(userId);
                } catch (error) {
                    return res.status(404).json({ error: "Usuário não encontrado" });
                }

                // Alterar senha
                await admin.auth().updateUser(userId, { password: novaSenha });

                // Atualizar Firestore
                await admin.firestore().collection("usuarios").doc(userId).update({
                    temSenhaDefinida: true,
                    dataAtualizacao: admin.firestore.FieldValue.serverTimestamp(),
                    senhaAlteradaPor: uid,
                    senhaAlteradaEm: admin.firestore.FieldValue.serverTimestamp(),
                });

                // 👈 AUDITORIA
                await admin.firestore().collection("auditoria").add({
                    acao: "SENHA_ALTERADA",
                    usuarioId: userId,
                    executadoPor: uid,
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    ip: req.headers['x-forwarded-for'] || req.connection.remoteAddress,
                });

                res.status(200).json({
                    success: true,
                    message: "Senha alterada com sucesso"
                });

            } catch (error) {
                console.error('💥 Erro:', error);

                if (error.code === 'auth/user-not-found') {
                    return res.status(404).json({ error: "Usuário não encontrado" });
                }

                res.status(500).json({ error: "Erro interno" });
            }
        });
    });
});

// ✅ LIMPEZA PERIÓDICA DO CACHE
setInterval(() => {
    const now = Date.now();
    const windowMs = 60000;

    for (const [ip, requests] of requestCache.entries()) {
        const filteredRequests = requests.filter(time => time > now - windowMs);
        if (filteredRequests.length === 0) {
            requestCache.delete(ip);
        } else {
            requestCache.set(ip, filteredRequests);
        }
    }
}, 30000); // A cada 30 segundos

// ✅ FUNÇÃO: Atualizar status do usuário (Ativar/Inativar)
exports.atualizarStatusUsuario = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        console.log('🎯 [FUNCTION] atualizarStatusUsuario chamada');

        try {
            if (req.method !== "POST") {
                return res.status(405).send({ error: "Método não permitido" });
            }

            const authHeader = req.headers.authorization || "";
            const idToken = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : null;

            if (!idToken) {
                return res.status(401).send({ error: "Token não fornecido" });
            }

            const decodedToken = await admin.auth().verifyIdToken(idToken);
            const uid = decodedToken.uid;

            // Verificar se é admin
            const userDoc = await admin.firestore().collection("usuarios").doc(uid).get();
            if (!userDoc.exists || !userDoc.data().isAdmin) {
                return res.status(403).send({ error: "Acesso negado" });
            }

            const { userId, ativo } = req.body;

            if (!userId || typeof ativo !== 'boolean') {
                return res.status(400).send({ error: "Dados inválidos" });
            }

            // 1. Atualizar Firestore
            await admin.firestore().collection("usuarios").doc(userId).update({
                ativo: ativo,
                dataAtualizacao: admin.firestore.FieldValue.serverTimestamp(),
                atualizadoPor: uid,
            });

            // 2. Atualizar Auth (disabled é o inverso de ativo)
            await admin.auth().updateUser(userId, {
                disabled: !ativo
            });

            console.log(`✅ Status atualizado: ${userId} -> ${ativo ? 'Ativo' : 'Inativo'}`);

            res.status(200).send({
                success: true,
                message: `Usuário ${ativo ? 'ativado' : 'inativado'} com sucesso`
            });

        } catch (error) {
            console.error('💥 Erro:', error);

            if (error.code === 'auth/user-not-found') {
                return res.status(404).send({ error: "Usuário não encontrado" });
            }

            res.status(500).send({ error: "Erro interno" });
        }
    });
});

// ✅ FUNÇÃO: Teste de conexão
exports.testeConexao = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        console.log('🎯 [FUNCTION] testeConexao chamada');
        res.status(200).send({
            success: true,
            message: "Conexão OK - Gen 1 funcionando!",
            timestamp: new Date().toISOString()
        });
    });
});

// ✅ FUNÇÃO: Sincronização automática (Opcional - para sincronizar automaticamente)
exports.sincronizarStatusUsuario = functions.firestore
    .document('usuarios/{userId}')
    .onUpdate(async (change, context) => {
        try {
            const beforeData = change.before.data();
            const afterData = change.after.data();
            const userId = context.params.userId;

            // Verificar se o status "ativo" mudou
            if (beforeData.ativo !== afterData.ativo) {
                console.log(`🔄 Sincronizando status: ${userId} -> ${afterData.ativo}`);

                // Atualizar Auth
                await admin.auth().updateUser(userId, {
                    disabled: !afterData.ativo
                });

                console.log(`✅ Auth sincronizado: ${userId} -> ${afterData.ativo ? 'Ativo' : 'Inativo'}`);
            }

            return { success: true };

        } catch (error) {
            console.error('❌ Erro na sincronização:', error);
            return { success: false, error: error.message };
        }
    });



/*
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

admin.initializeApp();

// ✅ CONFIGURAÇÕES
const SECURITY_CONFIG = {
maxPasswordLength: 100,
minPasswordLength: 6,
maxNameLength: 100,
maxEmailLength: 100,
maxPhoneLength: 20,
};

// ✅ FUNÇÕES DE VALIDAÇÃO
const isValidEmail = (email) => {
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
return emailRegex.test(email) && email.length <= SECURITY_CONFIG.maxEmailLength;
};

const isValidPassword = (password) => {
return password &&
    password.length >= SECURITY_CONFIG.minPasswordLength &&
    password.length <= SECURITY_CONFIG.maxPasswordLength;
};

// ✅ FUNÇÃO PRINCIPAL: Criar usuário completo
exports.criarUsuarioCompleto = functions.https.onRequest((req, res) => {
cors(req, res, async () => {
    console.log('🎯 [FUNCTION] criarUsuarioCompleto chamada');

    try {
        // 1. Verificar método
        if (req.method !== "POST") {
            return res.status(405).send({ error: "Método não permitido" });
        }

        // 2. Validar token
        const authHeader = req.headers.authorization || "";
        const idToken = authHeader.startsWith("Bearer ") ?
            authHeader.substring(7) : null;

        if (!idToken) {
            return res.status(401).send({ error: "Token não fornecido" });
        }

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const uid = decodedToken.uid;

        // 3. Verificar se é admin
        const userDoc = await admin.firestore().collection("usuarios").doc(uid).get();
        if (!userDoc.exists || !userDoc.data().isAdmin) {
            return res.status(403).send({ error: "Acesso negado - apenas administradores" });
        }

        // 4. Validar dados
        const { email, senha, nome, telefone, perfil, isAdmin = false } = req.body;

        if (!email || !senha || !nome || !perfil) {
            return res.status(400).send({ error: "Dados incompletos" });
        }

        if (!isValidEmail(email)) {
            return res.status(400).send({ error: "E-mail inválido" });
        }

        if (!isValidPassword(senha)) {
            return res.status(400).send({ error: "Senha deve ter pelo menos 6 caracteres" });
        }

        // 5. Verificar se email existe
        try {
            await admin.auth().getUserByEmail(email);
            return res.status(400).send({ error: "E-mail já cadastrado" });
        } catch (error) {
            // Email não existe, pode continuar
        }

        // 6. Criar usuário no Auth
        let userRecord;
        try {
            userRecord = await admin.auth().createUser({
                email: email.toLowerCase(),
                password: senha,
                displayName: nome,
                phoneNumber: telefone || undefined,
                disabled: false,
                emailVerified: false,
            });
            console.log('✅ Usuário criado no Auth:', userRecord.uid);
        } catch (error) {
            console.error('❌ Erro ao criar no Auth:', error);
            return res.status(400).send({ error: "Erro ao criar usuário: " + error.message });
        }

        // 7. Salvar no Firestore
        try {
            const usuarioData = {
                id: userRecord.uid,
                nome: nome,
                email: email.toLowerCase(),
                telefone: telefone || null,
                perfil: {
                    id: perfil.id || 'default',
                    nome: perfil.nome || 'Usuário',
                    descricao: perfil.descricao || '',
                    permissoes: perfil.permissoes || [],
                    ativo: perfil.ativo !== false,
                },
                dataCriacao: admin.firestore.FieldValue.serverTimestamp(),
                ativo: true,
                emailVerificado: false,
                isAdmin: isAdmin,
                temSenhaDefinida: true,
                criadoPor: uid,
            };

            await admin.firestore().collection("usuarios").doc(userRecord.uid).set(usuarioData);
            console.log('✅ Usuário salvo no Firestore');

        } catch (error) {
            // Compensação
            await admin.auth().deleteUser(userRecord.uid);
            throw error;
        }

        // 8. Retornar sucesso
        res.status(200).send({
            success: true,
            userId: userRecord.uid,
            message: "Usuário criado com sucesso!",
            data: {
                id: userRecord.uid,
                email: userRecord.email,
                nome: userRecord.displayName,
            }
        });

    } catch (error) {
        console.error('💥 Erro geral:', error);
        res.status(500).send({ error: "Erro interno do servidor" });
    }
});
});

// ✅ FUNÇÃO: Alterar senha
exports.alterarSenhaUsuario = functions.https.onRequest((req, res) => {
cors(req, res, async () => {
    console.log('🎯 [FUNCTION] alterarSenhaUsuario chamada');

    try {
        if (req.method !== "POST") {
            return res.status(405).send({ error: "Método não permitido" });
        }

        const authHeader = req.headers.authorization || "";
        const idToken = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : null;

        if (!idToken) {
            return res.status(401).send({ error: "Token não fornecido" });
        }

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const uid = decodedToken.uid;

        // Verificar se é admin
        const userDoc = await admin.firestore().collection("usuarios").doc(uid).get();
        if (!userDoc.exists || !userDoc.data().isAdmin) {
            return res.status(403).send({ error: "Acesso negado" });
        }

        const { userId, novaSenha } = req.body;

        if (!userId || !novaSenha) {
            return res.status(400).send({ error: "Dados incompletos" });
        }

        if (!isValidPassword(novaSenha)) {
            return res.status(400).send({ error: "Senha deve ter pelo menos 6 caracteres" });
        }

        // Alterar senha
        await admin.auth().updateUser(userId, { password: novaSenha });

        // Atualizar Firestore
        await admin.firestore().collection("usuarios").doc(userId).update({
            temSenhaDefinida: true,
            dataAtualizacao: admin.firestore.FieldValue.serverTimestamp(),
        });

        res.status(200).send({
            success: true,
            message: "Senha alterada com sucesso"
        });

    } catch (error) {
        console.error('💥 Erro:', error);

        if (error.code === 'auth/user-not-found') {
            return res.status(404).send({ error: "Usuário não encontrado" });
        }

        res.status(500).send({ error: "Erro interno" });
    }
});
});

// ✅ FUNÇÃO: Atualizar status do usuário (Ativar/Inativar)
exports.atualizarStatusUsuario = functions.https.onRequest((req, res) => {
cors(req, res, async () => {
    console.log('🎯 [FUNCTION] atualizarStatusUsuario chamada');

    try {
        if (req.method !== "POST") {
            return res.status(405).send({ error: "Método não permitido" });
        }

        const authHeader = req.headers.authorization || "";
        const idToken = authHeader.startsWith("Bearer ") ? authHeader.substring(7) : null;

        if (!idToken) {
            return res.status(401).send({ error: "Token não fornecido" });
        }

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const uid = decodedToken.uid;

        // Verificar se é admin
        const userDoc = await admin.firestore().collection("usuarios").doc(uid).get();
        if (!userDoc.exists || !userDoc.data().isAdmin) {
            return res.status(403).send({ error: "Acesso negado" });
        }

        const { userId, ativo } = req.body;

        if (!userId || typeof ativo !== 'boolean') {
            return res.status(400).send({ error: "Dados inválidos" });
        }

        // 1. Atualizar Firestore
        await admin.firestore().collection("usuarios").doc(userId).update({
            ativo: ativo,
            dataAtualizacao: admin.firestore.FieldValue.serverTimestamp(),
            atualizadoPor: uid,
        });

        // 2. Atualizar Auth (disabled é o inverso de ativo)
        await admin.auth().updateUser(userId, {
            disabled: !ativo
        });

        console.log(`✅ Status atualizado: ${userId} -> ${ativo ? 'Ativo' : 'Inativo'}`);

        res.status(200).send({
            success: true,
            message: `Usuário ${ativo ? 'ativado' : 'inativado'} com sucesso`
        });

    } catch (error) {
        console.error('💥 Erro:', error);

        if (error.code === 'auth/user-not-found') {
            return res.status(404).send({ error: "Usuário não encontrado" });
        }

        res.status(500).send({ error: "Erro interno" });
    }
});
});

// ✅ FUNÇÃO: Teste de conexão
exports.testeConexao = functions.https.onRequest((req, res) => {
cors(req, res, async () => {
    console.log('🎯 [FUNCTION] testeConexao chamada');
    res.status(200).send({
        success: true,
        message: "Conexão OK - Gen 1 funcionando!",
        timestamp: new Date().toISOString()
    });
});
});

// ✅ FUNÇÃO: Sincronização automática (Opcional - para sincronizar automaticamente)
exports.sincronizarStatusUsuario = functions.firestore
.document('usuarios/{userId}')
.onUpdate(async (change, context) => {
    try {
        const beforeData = change.before.data();
        const afterData = change.after.data();
        const userId = context.params.userId;

        // Verificar se o status "ativo" mudou
        if (beforeData.ativo !== afterData.ativo) {
            console.log(`🔄 Sincronizando status: ${userId} -> ${afterData.ativo}`);

            // Atualizar Auth
            await admin.auth().updateUser(userId, {
                disabled: !afterData.ativo
            });

            console.log(`✅ Auth sincronizado: ${userId} -> ${afterData.ativo ? 'Ativo' : 'Inativo'}`);
        }

        return { success: true };

    } catch (error) {
        console.error('❌ Erro na sincronização:', error);
        return { success: false, error: error.message };
    }
});*/