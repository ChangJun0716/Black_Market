from fastapi import FastAPI
from kimsua import router as kimsua_router
from inhwan import router as inhwan_router
from changjun import router as changjun_router

str = "127.0.0.1"

app = FastAPI() 
app.include_router(kimsua_router,prefix="/kimsua")
app.include_router(inhwan_router,prefix="/inhwan")
app.include_router(changjun_router,prefix="/changjun")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app,host=str,port=8000)