# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM python:3.12-slim

RUN pip install --no-cache-dir uv==0.8.13

WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install dependencies
RUN uv sync --frozen --no-dev

# Copy the rest of the application
COPY . .

# Environment variables for Cloud Run
ENV MCP_TRANSPORT=sse
ENV PORT=8080

# Expose the port Cloud Run will listen on
EXPOSE 8080

# Run the server
CMD ["uv", "run", "python", "server.py"]
