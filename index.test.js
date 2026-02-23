import { app, server } from '.'
import request from 'supertest'
import User from './users/model.js'
import sequelize from './shared/database/database'
import { Sequelize } from 'sequelize'

describe('User', () => {
    let data
    let mockedSequelize

    beforeEach(async () => {
        data = {
            'dni': '1234567890',
            'name': 'Test'
        }
        jest.spyOn(console, 'log').mockImplementation(jest.fn())
        jest.spyOn(console, 'error').mockImplementation(jest.fn())
        jest.spyOn(sequelize, 'log').mockImplementation(jest.fn())
        mockedSequelize = new Sequelize({
            database: '<any name>',
            dialect: 'sqlite',
            username: 'root',
            password: '',
            validateOnly: true,
            models: [__dirname + '/models'],
        })
        await mockedSequelize.sync({ force: true })
    })

    afterEach(async () => {
        jest.clearAllMocks()
        await mockedSequelize.close()
    })

    afterAll(async () => {
        await new Promise((resolve) => server.close(resolve))
    })

    test('Get users', async () => {
        jest.spyOn(User, 'findAll').mockResolvedValue([data])
        const response = await request(app).get('/api/users')

        expect(response.status).toBe(200)
        expect(response.body).toEqual([data])
    })

    test('Get users - 500 on error', async () => {
        jest.spyOn(User, 'findAll').mockRejectedValue(new Error('DB error'))
        const response = await request(app).get('/api/users')

        expect(response.status).toBe(500)
        expect(response.body).toEqual({ error: 'Internal Server Error' })
    })

    test('Get user', async () => {
        jest.spyOn(User, 'findByPk').mockResolvedValue({ ...data, 'id': 1 })
        const response = await request(app).get('/api/users/1')

        expect(response.status).toBe(200)
        expect(response.body).toEqual({ ...data, 'id': 1 })
    })

    test('Get user - 404 when not found', async () => {
        jest.spyOn(User, 'findByPk').mockResolvedValue(null)
        const response = await request(app).get('/api/users/999')

        expect(response.status).toBe(404)
        expect(response.body).toEqual({ error: 'User not found: 999' })
    })

    test('Get user - 400 when id is not a number', async () => {
        const response = await request(app).get('/api/users/abc')

        expect(response.status).toBe(400)
    })

    test('Get user - 500 on error', async () => {
        jest.spyOn(User, 'findByPk').mockRejectedValue(new Error('DB error'))
        const response = await request(app).get('/api/users/1')

        expect(response.status).toBe(500)
        expect(response.body).toEqual({ error: 'Internal Server Error' })
    })

    test('Create user', async () => {
        jest.spyOn(User, 'findOne').mockResolvedValue(null)
        jest.spyOn(User, 'create').mockResolvedValue({ ...data, 'id': 1 })
        const response = await request(app).post('/api/users').send(data)

        expect(response.status).toBe(201)
        expect(response.body).toEqual({ ...data, 'id': 1 })
    })

    test('Create user - 400 when user already exists', async () => {
        jest.spyOn(User, 'findOne').mockResolvedValue({ ...data, 'id': 1 })
        const response = await request(app).post('/api/users').send(data)

        expect(response.status).toBe(400)
        expect(response.body).toEqual({ error: 'User already exists: ' + data.dni })
    })

    test('Create user - 400 when body invalid (missing name)', async () => {
        const response = await request(app).post('/api/users').send({ dni: '123' })

        expect(response.status).toBe(400)
        expect(response.body).toHaveProperty('errors')
    })

    test('Create user - 400 when body invalid (missing dni)', async () => {
        const response = await request(app).post('/api/users').send({ name: 'Test' })

        expect(response.status).toBe(400)
        expect(response.body).toHaveProperty('errors')
    })

    test('Create user - 500 on error', async () => {
        jest.spyOn(User, 'findOne').mockResolvedValue(null)
        jest.spyOn(User, 'create').mockRejectedValue(new Error('DB error'))
        const response = await request(app).post('/api/users').send(data)

        expect(response.status).toBe(500)
        expect(response.body).toEqual({ error: 'Internal Server Error' })
    })
})
