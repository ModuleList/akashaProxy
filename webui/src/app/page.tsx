'use client'

import Container from '@mui/material/Container';
import Chip from '@mui/material/Chip';
import InfoLine from '@/component/InfoLine';
import Stack from '@mui/material/Stack';
import Fab from '@mui/material/Fab';
import Button from '@mui/material/Button';
import { blueGrey, grey, lightBlue } from '@mui/material/colors';
import RotateRight from '@mui/icons-material/RotateRight';
import DoneAll from '@mui/icons-material/DoneAll';
import ClearIcon from '@mui/icons-material/Clear';
import Settings from '@mui/icons-material/Settings';
import GpsFixedIcon from '@mui/icons-material/GpsFixed';
import SpeedIcon from '@mui/icons-material/Speed';
import { createTheme, ThemeProvider } from '@mui/material/styles';
import Divider from '@mui/material/Divider';
import LoadingButton from '@mui/lab/LoadingButton';
import { exec, toast } from 'kernelsu';
import { useEffect, useState } from 'react';
import { CLASH_PATH } from './consts';
import yaml from 'js-yaml';
import Card from '@mui/material/Card';

const theme = createTheme({
  palette: {
    success: {
      main: lightBlue[900],
    },
    warning: {
      main: blueGrey[500],
    },
    info: {
      main: grey[50],
      dark: grey[100],
    },
  },
});


interface ClashInfo {
  version: string | null,
  daemon: number | null,
  webui: string | null,
  log: string | null,
  loading: boolean,
}
function ClashCard({ info, setClashInfo }: { info: ClashInfo, setClashInfo: (callback: (info: ClashInfo) => ClashInfo) => void }) {
  let bigButtonStyle: React.CSSProperties = {
    width: "100%",
    padding: "20px",
    textTransform: "none",
    fontSize: "18px",
    marginTop: "1rem",
    justifyContent: "start",
    borderRadius: "10px",
  };
  return (
    <>
      <ThemeProvider theme={theme}>
        <LoadingButton variant="contained" style={{
          width: "100%",
          padding: "24px 20px",
          textTransform: "none",
          fontSize: "20px",
          marginTop: "1rem",
          justifyContent: "start",
          borderRadius: "10px",
        }}
          loading={info.loading}
          startIcon={info.daemon != null ? (<DoneAll />) : (<ClearIcon />)}
          color={info.daemon != null ? "success" : "warning"}
          onClick={() => info.daemon != null ? stopClash(setClashInfo) : startClash(setClashInfo)}
        >{info.daemon != null ? "Clash 运行正常" : "Clash 已停止"}</LoadingButton>

        {info.daemon != null && (
          <Button variant="contained"
            style={bigButtonStyle}
            startIcon={<Settings />}
            color="info"
            onClick={() => window.location.href = info.webui ?? ""}
          >网页面板</Button>
        )}

        <Button variant="contained"
          style={bigButtonStyle}
          startIcon={<GpsFixedIcon />}
          color="info"
          onClick={() => window.location.href = "https://ip.skk.moe/"}
        >IP检查</Button>

        <Button variant="contained"
          style={bigButtonStyle}
          startIcon={<SpeedIcon />}
          color="info"
          onClick={() => window.location.href = "https://fast.com/"}
        >网络测速</Button>
      </ThemeProvider>

      <Card style={{ padding: '16px', backgroundColor: '#fafafc', marginTop: "2rem" }}>
        <Stack spacing={1}>
          <InfoLine title="版本">
            {(info.version != null && <Chip label={info.version} color="primary" variant="outlined" size='small' />)}
            {(info.version == null && <Chip label="未知" color="warning" variant="outlined" size='small' />)}
          </InfoLine>

          <InfoLine title="操作">
            <div>
              <Chip label={"删除缓存"} color="primary" size='small' onClick={() => deleteCache()} />
            </div>
          </InfoLine>

          {(info.log != null &&
            <>
              <Divider />
              <div>
                <p style={{ marginBottom: '1ex' }}>日志</p>
                <pre style={{
                  overflowX: "scroll",
                  borderRadius: '5px',
                  padding: '8px',
                  backgroundColor: "#eaeaec",
                  lineHeight: '1.3',
                  fontSize: '12px',
                  fontFamily: "monospace",
                  display: "block",
                  whiteSpace: 'pre',
                }}>{info.log}</pre>
              </div>
            </>
          )}
        </Stack>
      </Card>
    </>
  )
}

async function startClash(setClashInfo: (callback: (info: ClashInfo) => ClashInfo) => void) {
  setClashInfo(info => ({ ...info, loading: true }));
  try {
    let process = await exec(CLASH_PATH + '/tools/start.sh');
    if (process.errno != 0) {
      throw 'Failed: Exit code ' + process.errno + '\noutput: ' + process.stdout + '\nstderr: ' + process.stderr;
    }
    toast('Clash started');
    await updateInfo(setClashInfo);
  } catch (err) {
    console.error(err);
    toast("" + err);
  }
  setClashInfo(info => ({ ...info, loading: false }));
}

async function stopClash(setClashInfo: (callback: (info: ClashInfo) => ClashInfo) => void) {
  setClashInfo(info => ({ ...info, loading: true }));
  try {
    let process = await exec(CLASH_PATH + '/tools/stop.sh');
    if (process.errno != 0) {
      throw 'Failed: Exit code ' + process.errno + '\noutput: ' + process.stdout + '\nstderr: ' + process.stderr;
    }
    toast('Clash stopped');
    await updateInfo(setClashInfo);
  } catch (err) {
    console.error(err);
    toast("" + err);
  }
  setClashInfo(info => ({ ...info, loading: false }));
}

async function deleteCache() {
  try {
    let process = await exec(CLASH_PATH + '/tools/DeleteCache.sh');
    if (process.errno != 0) {
      throw 'Failed: Exit code ' + process.errno + '\noutput: ' + process.stdout + '\nstderr: ' + process.stderr;
    }
    toast('Cache deleted');
  } catch (err) {
    console.error(err);
    toast("" + err);
  }
}

async function updateInfo(setClashInfo: (callback: (info: ClashInfo) => ClashInfo) => void) {
  let running = false;
  // Get clash file name
  let clashFileName = null;
  try {
    let cmd = `source ${CLASH_PATH}/clash.config && printf "%s" $Clash_bin_name`;
    let process = await exec(cmd);
    if (process.errno != 0) {
      throw 'Failed to execute `' + cmd + '`: Exit code ' + process.errno;
    }
    clashFileName = process.stdout;
  } catch (err) {
    console.error(err);
    setClashInfo(info => ({ ...info, version: null }));
  }
  // Get clash version
  if (clashFileName) {
    try {
      let cmd = `"${CLASH_PATH}/clashkernel/${clashFileName}" -v`;
      let process = await exec(cmd);
      if (process.errno != 0) {
        throw 'Failed to execute `' + cmd + '`: Exit code ' + process.errno;
      }
      let version = process.stdout;
      let versionMatch = version.match(/\bv[0-9.]+\b/);
      if (versionMatch == null) {
        throw 'Failed to parse version from `' + version + '`';
      }
      version = versionMatch[0];
      setClashInfo(info => ({ ...info, version }));
    } catch (err) {
      console.error(err);
      setClashInfo(info => ({ ...info, version: null }));
    }
    // get daemon pid
    try {
      let cmd = `cat ${CLASH_PATH}/run/clash.pid`;
      let process = await exec(cmd);
      if (process.errno != 0) {
        throw 'Failed to execute `' + cmd + '`: Exit code ' + process.errno;
      }
      let pid = process.stdout.trim();
      // check if pid is running
      let getExeProcess = await exec(`test $(realpath /proc/${pid}/exe) == $(realpath "${CLASH_PATH}/clashkernel/${clashFileName}") || exit 1`);
      if (getExeProcess.errno == 0) {
        running = true;
        setClashInfo(info => ({ ...info, daemon: parseInt(pid) }));
      } else {
        setClashInfo(info => ({ ...info, daemon: null, webui: null }));
      }
    } catch (err) {
      console.error(err);
      setClashInfo(info => ({ ...info, daemon: null, webui: null }));
    }
  }

  if (running) {
    // Get webui address
    try {
      let configYamlProcess = await exec('cat ' + CLASH_PATH + '/run/config.yaml');
      if (configYamlProcess.errno != 0) {
        throw 'Failed to execute `cat ' + CLASH_PATH + '/run/webui.addr`: Exit code ' + configYamlProcess.errno;
      }
      let configYaml = configYamlProcess.stdout;
      let config = yaml.load(configYaml) as {
        'external-controller': string | undefined,
        'external-ui-name': string | undefined,
        'secret': string | undefined,
      };
      if (config['external-controller'] == undefined) throw 'external-controller not found in config.yaml';
      let port = config['external-controller'].split(':')[1];
      let path = config['external-ui-name'] ?? 'ui';
      let url = 'http://127.0.0.1:' + port + '/' + path + '?hostname=127.0.0.1&port=' + port;
      if (config['secret'] != undefined) url += '&secret=' + config['secret'];
      setClashInfo(info => ({ ...info, webui: url }));

    } catch (err) {
      console.error(err);
      setClashInfo(info => ({ ...info, webui: null }));
    }
  }
  // get logs
  try {
    let logProcess = await exec('tail -n 100 ' + CLASH_PATH + '/run/run.logs');
    if (logProcess.errno != 0) {
      throw 'Failed to execute `tail -n 100 ' + CLASH_PATH + '/run/run.logs`: Exit code ' + logProcess.errno;
    }
    setClashInfo(info => ({ ...info, log: logProcess.stdout }));
  } catch (err) {
    console.error(err);
    setClashInfo(info => ({ ...info, log: null }));
  }
}

function saveClashInfo(clashInfo: ClashInfo) {
  if (!clashInfo.loading && typeof window !== "undefined") {
    window.sessionStorage.setItem('clashInfo', JSON.stringify(clashInfo));
  }
}

function loadClashInfo(): ClashInfo {
  const defaultInfo: ClashInfo = { version: null, daemon: null, webui: null, log: null, loading: true };
  if (typeof window !== "undefined") {
    let clashInfo = window.sessionStorage.getItem('clashInfo');
    if (clashInfo == null) {
      return defaultInfo;
    }
    try {
      return JSON.parse(clashInfo);
    } catch (err) {
      console.error(err);
      return defaultInfo;
    }
  } else {
    return defaultInfo;
  }
}

export default function Home() {
  let [clashInfo, setClashInfo] = useState<ClashInfo>(loadClashInfo());
  useEffect(() => saveClashInfo(clashInfo), [clashInfo]);
  useEffect(() => {
    updateInfo(setClashInfo);
    setClashInfo(info => ({ ...info, loading: false }));
}, [])
  return (
    <>
      <Container maxWidth="md" style={{ paddingLeft: '0px', paddingRight: '0px' }}>
        <ClashCard info={clashInfo} setClashInfo={setClashInfo} />
      </Container>

      <Fab size="small" color="success" style={{ right: '1em', bottom: '1em', zIndex: 999, position: 'fixed' }} onClick={() => updateInfo(setClashInfo)}>
        <RotateRight />
      </Fab>
    </>
  )
}
