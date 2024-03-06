'use client'

import Container from '@mui/material/Container';
import Grid from '@mui/material/Unstable_Grid2';
import Card from '@mui/material/Card';
import Typography from '@mui/material/Typography';
import Chip from '@mui/material/Chip';
import InfoLine from '@/component/InfoLine';
import Stack from '@mui/material/Stack';
import Fab from '@mui/material/Fab';
import RotateRight from '@mui/icons-material/RotateRight';
import Divider from '@mui/material/Divider';
import { exec, toast } from 'kernelsu';
import { useEffect, useState } from 'react';
import { CLASH_PATH } from './consts';
import yaml from 'js-yaml';

interface ClashInfo {
  version: string | null,
  daemon: number | null,
  webui: string | null,
  log: string | null,
}
function ClashCard({ info, update }: { info: ClashInfo, update: () => void }) {
  return (
    <>
      <Typography variant="h6" style={{ marginBottom: '12px' }}>
        Clash
      </Typography>
      <Stack spacing={1}>
        <InfoLine title="Version">
          {(info.version != null && <Chip label={info.version} color="primary" variant="outlined" size='small' />)}
          {(info.version == null && <Chip label="Unknown" color="warning" variant="outlined" size='small' />)}
        </InfoLine>

        <InfoLine title="Daemon">
          {(info.daemon != null && <Chip label={"Running (" + info.daemon + ")"} color="success" variant="outlined" size='small' />)}
          {(info.daemon == null && <Chip label="Stopped" color="warning" variant="outlined" size='small' />)}
        </InfoLine>

        <InfoLine title="Operation">
          <div>
            <Chip label={"Start"} color="primary" size='small' onClick={() => startClash(update)} style={{ marginRight: '1ex' }} />
            <Chip label={"Stop"} color="primary" size='small' onClick={() => stopClash(update)} />
          </div>
        </InfoLine>

        {(info.webui != null &&
          <InfoLine title="WebUI">
            <Chip label={"Open"} color="primary" size='small' onClick={() => window.location.href = info.webui ?? ""} />
          </InfoLine>
        )}
        {(info.log != null &&
          <>
            <Divider />
            <div>
              <p style={{ marginBottom: '1ex' }}>Logs</p>
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
    </>
  )
}

async function startClash(update: () => void) {
  try {
    let process = await exec(CLASH_PATH + '/scripts/clash.service -s && ' + CLASH_PATH + '/scripts/clash.iptables -s');
    if (process.errno != 0) {
      throw 'Failed to start clash: Exit code ' + process.errno;
    }
    toast('Clash started');
    update();
  } catch (err) {
    console.error(err);
    toast("" + err);
  }
}

async function stopClash(update: () => void) {
  try {
    let process = await exec(CLASH_PATH + '/scripts/clash.service -k && ' + CLASH_PATH + '/scripts/clash.iptables -k');
    if (process.errno != 0) {
      throw 'Failed to start clash: Exit code ' + process.errno;
    }
    toast('Clash stopped');
    update();
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

export default function Home() {
  let [clashInfo, setClashInfo] = useState<ClashInfo>({ version: null, daemon: null, webui: null, log: null });
  useEffect(() => {
    updateInfo(setClashInfo);
  }, [])
  return (
    <>
      <Container maxWidth="md" style={{ paddingLeft: '0px', paddingRight: '0px' }}>
        <Grid container spacing={2}>
          <Grid xs={12} md={12}>
            <Card style={{ padding: '16px', backgroundColor: '#fafafc' }}><ClashCard info={clashInfo} update={() => updateInfo(setClashInfo)} /></Card>
          </Grid>
        </Grid>
      </Container>

      <Fab size="small" color="success" style={{ right: '1em', bottom: '1em', zIndex: 999, position: 'fixed' }} onClick={() => updateInfo(setClashInfo)}>
        <RotateRight />
      </Fab>
    </>
  )
}
