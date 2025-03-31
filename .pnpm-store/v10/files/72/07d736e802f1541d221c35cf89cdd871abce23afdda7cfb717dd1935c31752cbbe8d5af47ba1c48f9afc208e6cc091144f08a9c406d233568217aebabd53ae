const CHUNK_SIZE = 1048576
const ChunkActiveUploads = {}

const chunkUploadStart = (req, res) => {
  const uuid = Math.floor((1 + Math.random()) * 0x10000)
    .toString(16)
    .substring(1)
  ChunkActiveUploads[uuid] = {}

  return res.json({
    status: 'success',
    data: {
      session_id: uuid,
      start_offset: 0,
      end_offset: CHUNK_SIZE
    }
  })
}

const chunkUploadPart = (req, res) => {
  setTimeout(() => {
    const rand = Math.random()
    if (rand <= 0.25) {
      res.status(500)
      res.json({ status: 'error', error: 'server' })
    } else {
      res.send({ status: 'success' })
    }
  }, 100 + parseInt(Math.random() * 2000, 10))
}

const chunkUploadFinish = (req, res) => {
  setTimeout(() => {
    const rand = Math.random()
    if (rand <= 0.25) {
      res.status(500)
      res.json({ status: 'error', error: 'server' })
    } else {
      res.send({ status: 'success' })
    }
  }, 100 + parseInt(Math.random() * 2000, 10))
}

module.exports = (req, res) => {
  if (!req.body.phase) {
    return chunkUploadPart(req, res)
  }

  switch (req.body.phase) {
    case 'start':
      return chunkUploadStart(req, res)

    case 'upload':
      return chunkUploadPart(req, res)

    case 'finish':
      return chunkUploadFinish(req, res)
  }
}
